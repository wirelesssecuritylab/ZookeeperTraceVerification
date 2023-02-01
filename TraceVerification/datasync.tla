------------------------------ MODULE datasync ------------------------------
EXTENDS Naturals,TLC,Sequences,FiniteSets, Integers, ExternalSeqRecordParser2  

VARIABLE leader
VARIABLE follower
VARIABLE followerSendEpochToLeader
VARIABLE leaderReceivedEpochFromFollower
VARIABLE leaderCalculaterNewEpoch
VARIABLE followerReceivedNewEpochFromLeader
VARIABLE leaderSyncDataZxid
VARIABLE followerSyncDataZxid
VARIABLE offset
vars == <<leader, follower,followerSendEpochToLeader,leaderReceivedEpochFromFollower,leaderCalculaterNewEpoch,followerReceivedNewEpochFromLeader,leaderSyncDataZxid,followerSyncDataZxid,offset>>
Trace == ExSeqRcdParser2("./datasync.log")

(*   leader选举结束开启数据同步过程，数据同步过程分为如下阶段                *)
(*      1.follower发送epoch给leader                            *)
(*      2.leader接受follower发送的epoch                         *)
(*      3.leader重新计算epoch，为newEpoch，并发送newepoch给follower *)
(*      4.follower接受newEpoch，并发送ack消息给leader              *)
(*      5.leader接收到newepoch，开始数据同步，发送相应的Zxid            *)


\*<<[myId |-> 3, sid |-> 2], [myId |-> 3, sid |-> 1], [myId |-> 2, sid |-> 1]>>.
Init ==
       /\ leader = 0
       /\ follower = 0
       /\ followerSendEpochToLeader = 0
       /\ leaderReceivedEpochFromFollower = 0
       /\ leaderCalculaterNewEpoch = 0
       /\ followerReceivedNewEpochFromLeader = 0
       /\ leaderSyncDataZxid = 0
       /\ followerSyncDataZxid = 0
       /\ offset = 1
     
term == /\ offset > Len(Trace)
        /\ UNCHANGED vars  
        
        
get ==
       /\ offset <= Len(Trace)
       /\ offset' = offset + 1
       /\ leader'=Trace[offset].leader
       /\ follower' = Trace[offset].follower 
       /\ followerSendEpochToLeader'=Trace[offset].followerSendEpochToLeader
       /\ leaderReceivedEpochFromFollower' = Trace[offset].leaderReceivedEpochFromFollower 
       /\ leaderCalculaterNewEpoch'=Trace[offset].leaderCalculaterNewEpoch
       /\ followerReceivedNewEpochFromLeader' = Trace[offset].followerReceivedNewEpochFromLeader 
       /\ leaderSyncDataZxid'=Trace[offset].leaderSyncDataZxid
       /\ followerSyncDataZxid' = Trace[offset].followerSyncDataZxid       
  
Next == \/ get
        \/ term


         
Spec == Init /\ [][Next]_vars

EpochConsistency == followerSendEpochToLeader = leaderReceivedEpochFromFollower
NewEpochConsistency == leaderCalculaterNewEpoch = followerReceivedNewEpochFromLeader
SyncDataZxidConsistency == leaderSyncDataZxid = followerSyncDataZxid



=============================================================================
\* Modification History
\* Last modified Thu Apr 07 20:41:27 CST 2022 by niuzhi
\* Created Tue Mar 29 15:20:35 CST 2022 by niuzhi