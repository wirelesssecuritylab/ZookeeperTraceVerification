-------------------------- MODULE stateconsistency --------------------------
EXTENDS Naturals,TLC,Sequences,FiniteSets, Integers,StatesConsistencyInspect
\* Sequence to Set
RECURSIVE Seq2Set(_)
Seq2Set(S) ==
    IF S = <<>> THEN {}
    ELSE
        LET i == Head(S)
        IN {i} \cup Seq2Set(Tail(S))
        

IsInjective(f) == \A a,b \in DOMAIN f : f[a] = f[b] => a = b
SetToSeq(S) == CHOOSE f \in [1..Cardinality(S) -> S] : IsInjective(f) 

decideStateIsLeading(S) == \E x \in S:
                               x.State = "LEADING"
                                   
selectStateIsLeading(S) == { x \in S : 
                                         x.State = "LEADING"}

selectStateIsLeading2(S) == CHOOSE x \in S : 
                                      x.State = "LEADING"     
selectStateIsNotLeading(S) == { x \in S:
                                        x.State /= "LEADING"}


decideStateIsfOLLOWING(S,myid) == \A x \in S:
                                    /\ (x.State = "FOLLOWING") \/ (x.State = "LOOKING")
                                    /\ x.myId /= myid  
       
\*<<[myId |-> 1, State |-> "FOLLOWING"], [myId |-> 2, State |-> "LEADING"]>>
VARIABLES stateSeq,offset,statecollection,myId
vars == <<stateSeq,statecollection,offset,myId>>
Trace == StateConsistencyParser("./stateconsistency.log")

Init == /\ offset =1
        /\ stateSeq = <<>>
        /\ statecollection = {}
        /\ myId = 0
        
term == /\ offset > Len(Trace)
        /\ UNCHANGED vars 


stateconsistency == /\ offset <= Len(Trace)
                    /\ offset' = offset + 1
                    /\ stateSeq' = Trace[offset]
                    /\ statecollection' = Seq2Set(stateSeq')
                    /\ Assert(decideStateIsLeading(statecollection') = TRUE, "Existed state is Leader node")
                    /\ Assert(Len(SetToSeq(selectStateIsLeading(statecollection'))) = 1, "Leader is one node")
                    /\ myId' = selectStateIsLeading2(statecollection').myId
                    \*/\ PrintT(myId')
                    /\ Assert(decideStateIsfOLLOWING(selectStateIsNotLeading(statecollection'), myId') = TRUE, "other node is following")
                   
 
Next == \/ stateconsistency
        \/ term


         
Spec == Init /\ [][Next]_vars




                 
=============================================================================
\* Modification History
\* Last modified Thu Apr 07 20:41:27 CST 2022 by niuzhi
\* Created Tue Mar 29 15:20:35 CST 2022 by niuzhi