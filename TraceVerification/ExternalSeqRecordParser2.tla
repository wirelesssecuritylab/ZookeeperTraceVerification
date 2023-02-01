---- MODULE ExternalSeqRecordParser2 ----

EXTENDS Integers, Sequences, TLC

\* parses the log to a TLA+ sequence of TLA+ records
ExSeqRcdParser2(path) == CHOOSE x \in Seq([leader:Int,follower:Int,followerSendEpochToLeader:Int,leaderReceivedEpochFromFollower:Int,leaderCalculaterNewEpoch:Int,followerReceivedNewEpochFromLeader:Int,leaderSyncDataZxid:STRING,followerSyncDataZxid:STRING]):TRUE

========================================
\* Modification History
\* Last modified Thu Apr 07 20:41:27 CST 2022 by niuzhi
\* Created Tue Mar 29 15:20:35 CST 2022 by niuzhi