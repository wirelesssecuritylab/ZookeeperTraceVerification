---- MODULE ExternalSeqRecordParser3 ----

EXTENDS Integers, Sequences, TLC

\* parses the log to a TLA+ sequence of TLA+ records
ExSeqRcdParser3(path) == CHOOSE x \in Seq([myId:Int,myState:STRING,from:Int,proposedLeader:Int,proposedZxidHigh:Int,proposedZxidLow:Int,electionEpoch:Int,state:STRING,peerRpoch:Int,endvote:Int]):TRUE
========================================
\* Modification History
\* Last modified Thu Apr 07 20:41:27 CST 2022 by niuzhi
\* Created Tue Mar 29 15:20:35 CST 2022 by niuzhi