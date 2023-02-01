---------------------------- MODULE leaderevote ----------------------------


EXTENDS Naturals,TLC,Sequences,FiniteSets, Integers, ExternalSeqRecordParser3
\* Sequence to Set
RECURSIVE Seq2Set(_)
Seq2Set(S) ==
    IF S = <<>> THEN {}
    ELSE
        LET i == Head(S)
        IN {i} \cup Seq2Set(Tail(S))
        

\*过滤本轮选票中最大的的electionEpoch选票
selectMaxelectionEpoch(S) == { x \in S:
                                \A y \in S:
                                  y.electionEpoch <= x.electionEpoch}

\*判断本轮选票是否存在state为FOLLOWING的选票
decideStateExisted(S,state) ==  \E x \in S:
                                    /\ x.state =state   
\*过滤指定state的选票
selectVoteByState(S,state) == { x \in S:
                                 x.state = state}
\*判断准leader与选举结束后的leader是否相同
decideProposedLeaderEqualEndvote(S) == \A x \in S:
                                             /\ x.proposedLeader = x.endvote
\*过滤出来源于本节点的选票
selectvoteFromNodeSelf(S) == CHOOSE x \in S : 
                                            /\ x.myId = x.from
                                            /\ x.myState = "LOOKING"
                                            /\ x.state = "LOOKING"
                                            

\*判断选票状态是否全部为"LOOKING"
decideStateAllIsLOOKING(S) == \A x \in S:
                                    x.state = "LOOKING" 

\*过滤事务zxid最大的选票
selectVoteByZxid(S) == { x \in S:
                              \A y \in S:
                                \/ y.proposedZxidHigh < x.proposedZxidHigh
                                \/ ((y.proposedZxidHigh = x.proposedZxidHigh) /\ (y.proposedZxidLow <= x.proposedZxidLow))}

\*过滤事务myId最大的选票
selectVoteByMyid(S) =={ x \in S:
                           \A y \in S:
                             y.from <= x.from} 


VARIABLES evoteSeq,offset,evotecollection
vars == <<evoteSeq,evotecollection,offset>>
Trace == ExSeqRcdParser3("./leaderelection.log")

Init == /\ offset =1
        /\ evoteSeq = <<>>
        /\ evotecollection = {}
        
term == /\ offset > Len(Trace)
        /\ UNCHANGED vars  


election == /\ offset <= Len(Trace)
            /\ offset' = offset + 1
            /\ evoteSeq' = Trace[offset]
            /\ evotecollection' = Seq2Set(evoteSeq')
            /\ IF ((decideStateExisted(selectMaxelectionEpoch(evotecollection'),"FOLLOWING")) = TRUE)
               THEN /\ Assert(decideProposedLeaderEqualEndvote(selectVoteByState(selectMaxelectionEpoch(evotecollection'),"FOLLOWING")) = TRUE,"Failure of assertion at line 61, column 5.") 
               ELSE
                 /\ TRUE
            /\ IF ((decideStateExisted(selectMaxelectionEpoch(evotecollection'),"LEADING")) = TRUE)
               THEN /\ Assert(decideProposedLeaderEqualEndvote(selectVoteByState(selectMaxelectionEpoch(evotecollection'),"LEADING")) = TRUE, "Failure of assertion at line 66, column 5.")
               ELSE
                 /\ TRUE
            /\ Assert(selectvoteFromNodeSelf(evotecollection').proposedLeader = selectvoteFromNodeSelf(evotecollection').myId, "Failure of assertion at line 71, column 3.")
            /\ IF (decideStateAllIsLOOKING(selectMaxelectionEpoch(evotecollection')) = TRUE) 
               THEN
                /\ Assert(decideProposedLeaderEqualEndvote(selectVoteByMyid(selectVoteByZxid(selectMaxelectionEpoch(evotecollection')))) = TRUE, "Failure of assertion at line 74, column 4.")
               ELSE
                /\  TRUE  

Next == \/ election
        \/ term
        
Spec == Init /\ [][Next]_vars               



=============================================================================
\* Modification History
\* Last modified Thu Apr 07 20:41:27 CST 2022 by niuzhi
\* Created Tue Mar 29 15:20:35 CST 2022 by niuzhi