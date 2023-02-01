----------------------------- MODULE Zookeeper -----------------------------
EXTENDS Naturals,TLC,Sequences,FiniteSets, Integers, ExternalSeqRecordParser3,StatesConsistencyInspect,ExternalSeqRecordParser2, Broadcast,Broadcast2,Reals
VARIABLES evoteSeq,offset,evotecollection,offset_2,stateSeq,statecollection,leader, 
          follower,followerSendEpochToLeader,leaderReceivedEpochFromFollower,
          leaderCalculaterNewEpoch,followerReceivedNewEpochFromLeader,leaderSyncDataZxid,followerSyncDataZxid,offset_3,
          broadCastSeq,offset_4,broadCastCollection
vars == <<evoteSeq,offset,evotecollection,offset_2,stateSeq,statecollection,leader, 
          follower,followerSendEpochToLeader,leaderReceivedEpochFromFollower,
         leaderCalculaterNewEpoch,followerReceivedNewEpochFromLeader,leaderSyncDataZxid,followerSyncDataZxid,offset_3,
         broadCastSeq,offset_4,broadCastCollection>>


Trace == ExSeqRcdParser3("./leaderelection.log")
Trace2 == StateConsistencyParser("./stateconsistency.log")
Trace3 == ExSeqRcdParser2("./datasync.log")
Trace4 == broadcastparser("./broadcast.log")
Trace5 == broadcastparser2("./broadcast.log")

RECURSIVE Seq2Set(_)
Seq2Set(S) ==
    IF S = <<>> THEN {}
    ELSE
        LET i == Head(S)
        IN {i} \cup Seq2Set(Tail(S))       
(*==========================================rule1===================================================*)
\*过滤出来源于本节点的选票
selectvoteFromNodeSelf(S) == {temp \in S : 
                                          /\ temp.myId = temp.from
                                          /\ temp.myState = "LOOKING"
                                          /\ temp.state = "LOOKING"
                              }    
Rule1 ==  IF (offset /= 0) 
          THEN
           /\  \E vote \in selectvoteFromNodeSelf(evotecollection):
                                                              vote.proposedLeader = vote.myId 
          ELSE
           /\    TRUE                                                                                                                        
(*==========================================rule2===================================================*)
IsInjective(f) == \A a,b \in DOMAIN f : f[a] = f[b] => a = b
SetToSeq(S) == CHOOSE f \in [1..Cardinality(S) -> S] : IsInjective(f)                                                                
selectStateIsLeading(S) == { x \in S : 
                                      x.State = "LEADING"}
Rule2 == IF (offset_2 /= 0) 
         THEN
          /\    Len(SetToSeq(selectStateIsLeading(statecollection))) = 1
         ELSE
          /\    TRUE
(*==========================================rule3===================================================*) 
decideStateAllIsLOOKING(S) == \A x \in S:
                                    x.state = "LOOKING" 
selectMaxelectionEpoch(S) == { x \in S:
                                \A y \in S:
                                  y.electionEpoch <= x.electionEpoch}
selectVoteByZxid(S) == { x \in S:
                              \A y \in S:
                                \/ y.proposedZxidHigh < x.proposedZxidHigh
                                \/ ((y.proposedZxidHigh = x.proposedZxidHigh) 
                                    /\ (y.proposedZxidLow <= x.proposedZxidLow)
                                   )}
decideProposedLeaderEqualEndvote(S) == \A x \in S:
                                             /\ x.proposedLeader = x.endvote
selectVoteByMyid(S) =={ x \in S:
                           \A y \in S:
                             y.from <= x.from}
selectVoteByState(S,state) == { x \in S:
                                 x.state = state}
Rule3 == IF (offset_2 /= 0) 
         THEN
          /\ IF decideStateAllIsLOOKING(selectMaxelectionEpoch(evotecollection)) = TRUE
             THEN
              /\decideProposedLeaderEqualEndvote(
                selectVoteByMyid(
                selectVoteByZxid(selectMaxelectionEpoch(evotecollection)))) = TRUE
             ELSE
              /\decideProposedLeaderEqualEndvote(
                selectVoteByState(
                selectMaxelectionEpoch(evotecollection),"FOLLOWING")) = TRUE
              /\decideProposedLeaderEqualEndvote(
                selectVoteByState(selectMaxelectionEpoch(evotecollection),"LEADING")) = TRUE
         ELSE
          /\  TRUE
(*==========================================rule4===================================================*) 
Rule4 == IF (offset_3 /= 0) 
         THEN
          /\   leaderSyncDataZxid = followerSyncDataZxid
         ELSE
          /\  TRUE

Rule5 ==  IF (offset_3 /= 0) 
          THEN
           /\  followerSendEpochToLeader = leaderReceivedEpochFromFollower 
          ELSE
           /\ TRUE
Rule6 == IF (offset_3 /= 0) 
         THEN
          /\  leaderCalculaterNewEpoch = followerReceivedNewEpochFromLeader
         ELSE
          /\  TRUE
(*==========================================rule7===================================================*) 
selectLeaderNode(S) == CHOOSE temp \in S : 
                                        /\ temp.action = "LeaderLaunchProposal" 
                                             
selectNodeCommitTranslation(S) == { temp \in S:
                                            /\ temp.action = "Request2DataTree"
                                   }                                                                                
selectFollowerNode(S) == { temp \in S:
                                      /\ temp.action = "FollowerSendAckToLeader"}                                       
                                      
selectReceivedProposal(S) ==  { temp \in S:
                                      /\ temp.action = "ReceivedProposal"} 
decideWriteRequestTranslationConsistency(
       writeRequestCollection,
       NodeCommitTranslationCollection,nodeCount,
       Request2DataTreeCount)==
                                \A commitTranslation \in NodeCommitTranslationCollection:
                                /\ commitTranslation.sessionid = writeRequestCollection.sessionid
                                /\ commitTranslation.type = writeRequestCollection.type
                                /\ commitTranslation.cxid = writeRequestCollection.cxid
                                /\ commitTranslation.zxidHigh = writeRequestCollection.zxidHigh
                                /\ commitTranslation.zxidLow = writeRequestCollection.zxidLow
                                /\ commitTranslation.txntype = writeRequestCollection.txntype
                                /\ nodeCount = Request2DataTreeCount
Rule7 == IF (offset_4 /= 0) 
         THEN
          /\  decideWriteRequestTranslationConsistency(
                                         selectLeaderNode(broadCastCollection), 
                                         selectNodeCommitTranslation(broadCastCollection), 
                                         Len(SetToSeq(selectFollowerNode(broadCastCollection))) +1 ,
                                         Len(SetToSeq(selectNodeCommitTranslation(broadCastCollection)))
                                         )=TRUE
         ELSE
          /\  TRUE

\*判断proposal接受发送数据一致性
decideProposalConsistency(SendProposal,ReceivedProposal) ==
                              \A RP \in ReceivedProposal:
                               /\ RP.sessionid = SendProposal.sessionid
                               /\ RP.type = SendProposal.type
                               /\ RP.cxid = SendProposal.cxid
                               /\ RP.zxidHigh = SendProposal.zxidHigh
                               /\ RP.zxidLow = SendProposal.zxidLow 
Rule8 == IF (offset_4 /= 0) 
         THEN
          /\ decideProposalConsistency(
                                  selectLeaderNode(broadCastCollection),
                                  selectReceivedProposal(broadCastCollection)) =TRUE
         ELSE
          /\  TRUE 
                                  
                                                                   
                                  
decideOrder(zxidHigh_1,zxidLow_1,zxidHigh_2,zxidLow_2) == 
                                                       IF (zxidHigh_1 < zxidHigh_2) 
                                                       THEN
                                                        /\  TRUE
                                                       ELSE
                                                        /\  IF (zxidHigh_1 = zxidHigh_2) 
                                                            THEN
                                                             /\  IF (zxidLow_1 < zxidLow_2) 
                                                                 THEN
                                                                  /\  TRUE
                                                                 ELSE
                                                                  /\   FALSE
                                                            ELSE
                                                             /\   FALSE
globaOrderVerification(S1,S2) ==
                                /\\A temp \in S1:
                                   \A temp_2 \in S2:
                                     /\ IF ((temp.myId = temp_2.myId)) 
                                        THEN
                                         /\ decideOrder(temp.zxidHigh,
                                                        temp.zxidLow,
                                                        temp_2.zxidHigh,
                                                        temp_2.zxidLow)                                       
                                        ELSE
                                         /\ TRUE
Rule9 ==  IF (offset_4 /= 0) 
          THEN
           /\   IF ((offset_4 +1) <= Len(Trace5)) 
                THEN
                  /\ globaOrderVerification(Trace5[offset_4],Trace5[offset_4+1])
                ELSE
                  /\ TRUE
          ELSE
           /\  TRUE 

 
                                                                                                                                               
selectRule1Init == /\ offset = 0
                   /\ evoteSeq = <<>>
                   /\ evotecollection = {}
                                    
selectRule2Init == /\ offset_2 =0  
                   /\ stateSeq = <<>>
                   /\ statecollection ={}   
datasyncInit == /\ offset_3 = 0
                /\ leader = 0
                /\ follower = 0
                /\ followerSendEpochToLeader = 0
                /\ leaderReceivedEpochFromFollower = 0
                /\ leaderCalculaterNewEpoch = 0
                /\ followerReceivedNewEpochFromLeader = 0
                /\ leaderSyncDataZxid = 0
                /\ followerSyncDataZxid = 0                              
broadcastInit == /\ offset_4 = 0
                 /\ broadCastSeq = <<>>
                 /\ broadCastCollection =  {}
Init == /\ selectRule1Init
        /\ selectRule2Init 
        /\ datasyncInit 
        /\ broadcastInit 
 
                
selectRule1Next == /\ offset < Len(Trace) 
                   /\ offset' = offset + 1
                   /\ evoteSeq' = Trace[offset']         
                   /\ evotecollection' = Seq2Set(evoteSeq')
                   /\ UNCHANGED <<offset_2,stateSeq,statecollection,leader,follower,
                                 followerSendEpochToLeader,leaderReceivedEpochFromFollower,
                                 leaderCalculaterNewEpoch,followerReceivedNewEpochFromLeader,
                                 leaderSyncDataZxid,followerSyncDataZxid,offset_3,
                                 broadCastSeq,offset_4,broadCastCollection>> 
                                        
selectRule2Next == /\ offset_2 < Len(Trace2)
                   /\ offset_2' = offset_2 + 1
                   /\ stateSeq' = Trace2[offset_2']
                   /\ statecollection' = Seq2Set(stateSeq')
                   /\ UNCHANGED <<evoteSeq,offset,evotecollection,leader,follower,
                                 followerSendEpochToLeader,leaderReceivedEpochFromFollower,
                                 leaderCalculaterNewEpoch,followerReceivedNewEpochFromLeader,
                                 leaderSyncDataZxid,followerSyncDataZxid,offset_3,
                                 broadCastSeq,offset_4,broadCastCollection>> 

datasyncNext == /\ offset_3 < Len(Trace3)
                /\ offset_3' = offset_3 + 1
                /\ leader' =Trace3[offset_3'].leader
                /\ follower' = Trace3[offset_3'].follower 
                /\ followerSendEpochToLeader'=Trace3[offset_3'].followerSendEpochToLeader
                /\ leaderReceivedEpochFromFollower'=Trace3[offset_3'].leaderReceivedEpochFromFollower 
                /\ leaderCalculaterNewEpoch'=Trace3[offset_3'].leaderCalculaterNewEpoch
                /\ followerReceivedNewEpochFromLeader'=Trace3[offset_3'].followerReceivedNewEpochFromLeader 
                /\ leaderSyncDataZxid'=Trace3[offset_3'].leaderSyncDataZxid
                /\ followerSyncDataZxid'=Trace3[offset_3'].followerSyncDataZxid
                /\ UNCHANGED <<offset_2,stateSeq,statecollection,evoteSeq,offset,evotecollection,
                             broadCastSeq,offset_4,broadCastCollection>>
        
 
broadcastNext == /\  offset_4 < Len(Trace4)   
                 /\  offset_4' = offset_4 + 1  
                 /\  broadCastSeq' = Trace4[offset_4']
                 /\ broadCastCollection' = Seq2Set(broadCastSeq') 
                 /\ UNCHANGED <<evoteSeq,offset,evotecollection,offset_2,stateSeq,statecollection,leader, 
                                follower,followerSendEpochToLeader,leaderReceivedEpochFromFollower,
                                leaderCalculaterNewEpoch,followerReceivedNewEpochFromLeader,
                                leaderSyncDataZxid,followerSyncDataZxid,offset_3>> 
                 
        



selectRule1term == /\ offset >= Len(Trace)
                   /\ UNCHANGED vars
          
selectRule2term == /\ offset_2 >= Len(Trace2)
                   /\ UNCHANGED vars
 
datasyncterm == /\ offset_3 >= Len(Trace3)
                /\ UNCHANGED vars
                
broadcastterm == /\ offset_4 >= Len(Trace4)
                 /\ UNCHANGED vars
 
Next == \/ selectRule1Next
        \/ selectRule2Next
        \/ datasyncNext
        \/ broadcastNext
        \/ selectRule1term
        \/ selectRule2term
        \/ datasyncterm
        \/ broadcastterm
 
 

 
               
Spec == Init /\ [][Next]_vars        



                               



=============================================================================
\* Modification History
\* Last modified Thu Apr 07 20:41:27 CST 2022 by niuzhi
\* Created Tue Mar 29 15:20:35 CST 2022 by niuzhi
