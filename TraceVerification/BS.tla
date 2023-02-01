--------------------------------- MODULE BS ---------------------------------
EXTENDS FiniteSets, Sequences, Naturals, Integers, TLC, Broadcast,Broadcast2,Reals  

\* Sequence to Set
RECURSIVE Seq2Set(_)
Seq2Set(S) ==
    IF S = <<>> THEN {}
    ELSE
        LET i == Head(S)
        IN {i} \cup Seq2Set(Tail(S))
        
        

VARIABLES broadCastSeq,offset,broadCastCollection
vars == <<broadCastSeq,offset,broadCastCollection>>


                                      


Init == /\ offset = 1
        /\ broadCastSeq = <<>>
        /\ broadCastCollection = {}

Trace == broadcastparser("./broadcast.log")
Trace2 == broadcastparser2("./broadcast.log")
IsInjective(f) == \A a,b \in DOMAIN f : f[a] = f[b] => a = b  
SetToSeq(S) == CHOOSE f \in [1..Cardinality(S) -> S] : IsInjective(f)                                       

\*获取leader节点
selectLeaderNode(S) == CHOOSE temp \in S : 
                                        /\ temp.action = "LeaderLaunchProposal" 
                                             
\*节点向数据库提交的事务
selectNodeCommitTranslation(S) == { temp \in S:
                                            /\ temp.action = "Request2DataTree"
                                   }                                           
                                      
\*获取Follower节点
selectFollowerNode(S) == { temp \in S:
                                      /\ temp.action = "FollowerSendAckToLeader"}  
                                      
                                      
\*选择接受到的proposal
selectReceivedProposal(S) ==  { temp \in S:
                                      /\ temp.action = "ReceivedProposal"} 
\*判断节点提交的事务是否与发起的写请求一致
decideWriteRequestTranslationConsistency(writeRequestCollection,NodeCommitTranslationCollection,nodeCount,Request2DataTreeCount)==
                                \A commitTranslation \in NodeCommitTranslationCollection:
                                /\ commitTranslation.sessionid = writeRequestCollection.sessionid
                                /\ commitTranslation.type = writeRequestCollection.type
                                /\ commitTranslation.cxid = writeRequestCollection.cxid
                                /\ commitTranslation.zxidHigh = writeRequestCollection.zxidHigh
                                /\ commitTranslation.zxidLow = writeRequestCollection.zxidLow
                                /\ commitTranslation.txntype = writeRequestCollection.txntype
                                /\ nodeCount = Request2DataTreeCount
\*判断proposal接受发送数据一致性
decideProposalConsistency(SendProposal,ReceivedProposal) ==
                              \A RP \in ReceivedProposal:
                               /\ RP.sessionid = SendProposal.sessionid
                               /\ RP.type = SendProposal.type
                               /\ RP.cxid = SendProposal.cxid
                               /\ RP.zxidHigh = SendProposal.zxidHigh
                               /\ RP.zxidLow = SendProposal.zxidLow


   
\*事务提交全局顺序验证
SelectNodeByMyId(myId_,S) == CHOOSE x \in S : x.myId = myId_ 


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
                                         /\ decideOrder(temp.zxidHigh,temp.zxidLow,temp_2.zxidHigh,temp_2.zxidLow)
                                        
                                        ELSE
                                         /\ TRUE
   
broadcast == /\ offset <= Len(Trace)
             /\ offset' = offset + 1
             /\ broadCastSeq' = Trace[offset]
             /\ broadCastCollection' = Seq2Set(broadCastSeq')
             /\ Assert(decideWriteRequestTranslationConsistency(selectLeaderNode(broadCastCollection'), selectNodeCommitTranslation(broadCastCollection'), Len(SetToSeq(selectFollowerNode(broadCastCollection'))) +1 ,  Len(SetToSeq(selectNodeCommitTranslation(broadCastCollection'))))=TRUE ,
                       "WriteTranslationConsistency")
             /\ Assert(decideProposalConsistency(selectLeaderNode(broadCastCollection'),selectReceivedProposal(broadCastCollection')) =TRUE , "Proposal consitency")   
             /\ IF ((offset +1) <= Len(Trace2)) 
                THEN
                  /\ globaOrderVerification(Trace2[offset],Trace2[offset+1])
                ELSE
                  /\ TRUE
             
 


term == /\ offset > Len(Trace)
        /\ UNCHANGED vars

Next == \/ broadcast
        \/ term
        
Spec == Init /\ [][Next]_vars  



=============================================================================
\* Modification History
\* Last modified Thu Apr 07 20:41:27 CST 2022 by niuzhi
\* Created Tue Mar 29 15:20:35 CST 2022 by niuzhi