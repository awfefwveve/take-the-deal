import base64
import unittest
from urllib.parse import urlencode
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from reward_ledger import RewardLedger, Rejected


class LedgerTests(unittest.TestCase):
    def setUp(self):
        self.now = 1800000000
        self.private = ec.generate_private_key(ec.SECP256R1())
        public = self.private.public_key().public_bytes(serialization.Encoding.PEM, serialization.PublicFormat.SubjectPublicKeyInfo)
        self.ledger = RewardLedger(":memory:", {"7": public}, ["ad-unit"], lambda: self.now)
        self.ticket = self.ledger.issue("player-a", 2)

    def tearDown(self):
        self.ledger.db.close()

    def callback(self, **changes):
        values = dict(ad_network="test", ad_unit="ad-unit", custom_data=self.ticket,
                      reward_amount="1", reward_item="deal", timestamp=str(self.now * 1000),
                      transaction_id="transaction-1", user_id="player-a")
        values.update(changes)
        query = urlencode(sorted(values.items()))
        signature = self.private.sign(query.encode(), ec.ECDSA(hashes.SHA256()))
        return query + "&signature=" + base64.urlsafe_b64encode(signature).decode().rstrip("=") + "&key_id=7"

    def test_reward_once_and_consume_once(self):
        callback = self.callback()
        self.assertTrue(self.ledger.verify_and_grant(callback))
        self.assertFalse(self.ledger.verify_and_grant(callback))
        self.assertEqual(self.ledger.consume("player-a", self.ticket), 2)
        with self.assertRaises(Rejected): self.ledger.consume("player-a", self.ticket)

    def test_cannot_consume_before_ssv(self):
        with self.assertRaises(Rejected): self.ledger.consume("player-a", self.ticket)

    def test_tampering(self):
        with self.assertRaises(Rejected): self.ledger.verify_and_grant(self.callback().replace("reward_amount=1", "reward_amount=999"))

    def test_wrong_identity(self):
        with self.assertRaises(Rejected): self.ledger.verify_and_grant(self.callback(user_id="player-b"))

    def test_wrong_ad_unit(self):
        with self.assertRaises(Rejected): self.ledger.verify_and_grant(self.callback(ad_unit="another-app"))

    def test_expired(self):
        callback = self.callback()
        self.now += 601
        with self.assertRaises(Rejected): self.ledger.verify_and_grant(callback)

    def test_second_transaction_same_intent(self):
        self.ledger.verify_and_grant(self.callback())
        with self.assertRaises(Rejected): self.ledger.verify_and_grant(self.callback(transaction_id="transaction-2"))

    def test_duplicate_fields(self):
        with self.assertRaises(Rejected): self.ledger.verify_and_grant("user_id=attacker&" + self.callback())

    def test_unknown_key(self):
        with self.assertRaises(Rejected): self.ledger.verify_and_grant(self.callback().replace("key_id=7", "key_id=9"))

    def test_one_pending(self):
        with self.assertRaises(Rejected): self.ledger.issue("player-a", 3)

    def test_other_player_cannot_consume(self):
        self.ledger.verify_and_grant(self.callback())
        with self.assertRaises(Rejected): self.ledger.consume("player-b", self.ticket)
        self.assertEqual(self.ledger.consume("player-a", self.ticket), 2)

    def test_cancelled_or_unknown_intent(self):
        with self.assertRaises(Rejected): self.ledger.verify_and_grant(self.callback(custom_data="fake"))

    def test_unsigned_client_callback(self):
        with self.assertRaises(Rejected): self.ledger.verify_and_grant("complete=true&power=19")


if __name__ == "__main__": unittest.main()
