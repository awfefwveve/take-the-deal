"""Server-only reference core. Not an HTTP service or deployed backend.

The HTTP/auth layer must supply authenticated player identities to issue(),
obtain Google's keys from the fixed official HTTPS endpoint and refresh daily.
Never receive a public key, player identity or grant result from the client.
https://developers.google.com/admob/android/ssv
"""
import base64
import secrets
import sqlite3
import time
from urllib.parse import parse_qsl

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec

GOOGLE_KEYS_URL = "https://www.gstatic.com/admob/reward/verifier-keys.json"


class Rejected(ValueError):
    pass


class RewardLedger:
    def __init__(self, database, trusted_keys, allowed_ad_units, clock=time.time):
        self.db = sqlite3.connect(database, isolation_level=None, timeout=10)
        self.db.execute("PRAGMA foreign_keys=ON")
        self.db.executescript("""
            CREATE TABLE IF NOT EXISTS intents (
                id TEXT PRIMARY KEY, player TEXT NOT NULL, power INTEGER NOT NULL,
                expires INTEGER NOT NULL, claimed INTEGER NOT NULL DEFAULT 0
            );
            CREATE TABLE IF NOT EXISTS rewards (
                transaction_id TEXT PRIMARY KEY,
                intent TEXT NOT NULL UNIQUE REFERENCES intents(id),
                player TEXT NOT NULL, power INTEGER NOT NULL,
                consumed INTEGER NOT NULL DEFAULT 0
            );
        """)
        self.keys = trusted_keys  # Server-owned key cache, keyed by Google key_id.
        self.ad_units = frozenset(allowed_ad_units)
        self.clock = clock

    def issue(self, authenticated_player, power):
        """Call only after auth, eligibility, rate limit and integrity checks.

        The public HTTP layer must not expose arbitrary player/power selection.
        The server game session must decide the eligible power.
        """
        if not isinstance(authenticated_player, str) or not 1 <= len(authenticated_player) <= 128:
            raise Rejected("Invalid principal")
        if type(power) is not int or power not in range(20):
            raise Rejected("Invalid power")
        now = int(self.clock())
        self.db.execute("BEGIN IMMEDIATE")
        try:
            active = self.db.execute(
                "SELECT 1 FROM intents WHERE player=? AND claimed=0 AND expires>?",
                (authenticated_player, now),
            ).fetchone()
            if active:
                raise Rejected("One pending intent per player")
            ticket = secrets.token_urlsafe(32)
            self.db.execute("INSERT INTO intents VALUES (?,?,?,?,0)",
                            (ticket, authenticated_player, power, now + 600))
            self.db.execute("COMMIT")
            return ticket
        except Exception:
            self.db.execute("ROLLBACK")
            raise

    def verify_and_grant(self, raw_query):
        """Accept raw, unmodified Google query, without leading '?'.

        Verify original bytes, not re-encoded or sorted parameters. A successful
        client ad callback is never accepted here. Returns True only for a new
        ledger entry; legitimate duplicate callbacks are idempotent.
        """
        if not isinstance(raw_query, str) or len(raw_query) > 8192:
            raise Rejected("Invalid callback")
        signed, separator, suffix = raw_query.partition("&signature=")
        if not separator:
            raise Rejected("Missing signature")
        try:
            pairs = parse_qsl(raw_query, keep_blank_values=True, strict_parsing=True)
        except ValueError as exc:
            raise Rejected("Malformed query") from exc
        params = dict(pairs)
        if len(params) != len(pairs):
            raise Rejected("Duplicate parameters")
        tail = parse_qsl("signature=" + suffix, keep_blank_values=True)
        if [k for k, _ in tail] != ["signature", "key_id"]:
            raise Rejected("Invalid signature boundary")
        required = {"ad_unit", "custom_data", "user_id", "transaction_id", "timestamp", "reward_amount", "reward_item", "signature", "key_id"}
        if not required.issubset(params):
            raise Rejected("Missing fields")
        if params["key_id"] not in self.keys:
            raise Rejected("Unknown signing key; refresh trusted cache")
        try:
            signature = params["signature"]
            signature = base64.b64decode(signature + "=" * (-len(signature) % 4), altchars=b"-_", validate=True)
            key = serialization.load_pem_public_key(self.keys[params["key_id"]])
            if not isinstance(key, ec.EllipticCurvePublicKey) or not isinstance(key.curve, ec.SECP256R1):
                raise Rejected("Unexpected key algorithm")
            key.verify(signature, signed.encode("utf-8"), ec.ECDSA(hashes.SHA256()))
        except (InvalidSignature, ValueError, TypeError) as exc:
            raise Rejected("Bad signature") from exc
        try:
            stamp = int(params["timestamp"]) / 1000
        except ValueError as exc:
            raise Rejected("Invalid timestamp") from exc
        if abs(self.clock() - stamp) > 600:
            raise Rejected("Expired callback")
        if params["ad_unit"] not in self.ad_units:
            raise Rejected("Wrong ad unit")
        if params["reward_amount"] != "1" or params["reward_item"] != "deal":
            raise Rejected("Unexpected configured reward")
        transaction = params["transaction_id"]
        if not transaction or len(transaction) > 256:
            raise Rejected("Invalid transaction")
        self.db.execute("BEGIN IMMEDIATE")
        try:
            existing = self.db.execute("SELECT intent,player FROM rewards WHERE transaction_id=?", (transaction,)).fetchone()
            if existing:
                if existing != (params["custom_data"], params["user_id"]):
                    raise Rejected("Transaction mismatch")
                self.db.execute("COMMIT")
                return False
            row = self.db.execute("SELECT player,power,expires,claimed FROM intents WHERE id=?", (params["custom_data"],)).fetchone()
            if not row or row[0] != params["user_id"] or row[2] < self.clock() or row[3]:
                raise Rejected("Intent invalid, expired or used")
            self.db.execute("INSERT INTO rewards VALUES (?,?,?,?,0)", (transaction, params["custom_data"], row[0], row[1]))
            self.db.execute("UPDATE intents SET claimed=1 WHERE id=?", (params["custom_data"],))
            self.db.execute("COMMIT")
            return True
        except Exception:
            self.db.execute("ROLLBACK")
            raise

    def consume(self, authenticated_player, ticket):
        """Called by authenticated game-session endpoint, not by SSV webhook.

        A lost HTTP response needs an idempotent server session/action ID in the
        transport layer. Do not regrant automatically after a network timeout.
        """
        self.db.execute("BEGIN IMMEDIATE")
        try:
            row = self.db.execute("SELECT power,consumed FROM rewards WHERE intent=? AND player=?", (ticket, authenticated_player)).fetchone()
            if not row or row[1]:
                raise Rejected("No unconsumed verified reward")
            self.db.execute("UPDATE rewards SET consumed=1 WHERE intent=?", (ticket,))
            self.db.execute("COMMIT")
            return row[0]
        except Exception:
            self.db.execute("ROLLBACK")
            raise
