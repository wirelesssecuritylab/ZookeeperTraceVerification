---- MODULE Broadcast ----

EXTENDS Integers, Sequences, TLC

\* parses the log to a TLA+ sequence of TLA+ records
broadcastparser(path) == CHOOSE x \in Seq([state:Int,myId:Int,action:STRING,sessionid:STRING,type:STRING,cxid:STRING,zxid:STRING,txntype:STRING,reqpath:STRING]):TRUE
========================================
\* Modification History
\* Last modified Thu Apr 07 20:41:27 CST 2022 by niuzhi
\* Created Tue Mar 29 15:20:35 CST 2022 by niuzhi
