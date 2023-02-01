import os

'''
 1.TLA+ interface compile command
    javac -cp tla2tools.jar ExternalSeqRecordParser2.java
'''


'''
读取zookeeper日志，并且过滤1022标签日志，并输入队列
Parameters:
  zookerloglocation -- 日志位置
'''
def fileReadZookeeperLog(zookerloglocation):
    list = []
    file = open(zookerloglocation,mode='r',encoding='utf-8')
    for (num, value) in enumerate(file):
        #print("line num is: ", num, "content:", value)
        if '1022' in value and '1022 start connection' not in value and '1022 end connection' not in value:
            list.append(str(num) + "--"+value)
    file.close()
    return list

'''
删选含有QuorumPeer日志
'''
def selectQuorumPeerLog(result):
    list = []
    for index in range(len(result)):
        if 'QuorumPeer' in result[index]:
            list.append(result[index])
    return list

def selectZookeeperState(result,stateconsistencyout):
    deleteFile(stateconsistencyout)
    stateconsistencyoutfile = open(stateconsistencyout, 'w')
    leaderelectionList = []
    leaderelectionList2 = [0, 0]
    for index in range(len(result)):
        if '1022 follower sync data' in result[index]:
            leaderelectionList2[0] = index
        elif '1022 follower send epoch' in result[index]:
            leaderelectionList2[1] = index
        if leaderelectionList2[1] > leaderelectionList2[0]:
            leaderelectionList.append(leaderelectionList2)
            leaderelectionList2 = [0, 0]

    for index_1 in range(len(leaderelectionList)):
        dict = {}
        dict['myId:0'] = 'State:LOOKING'
        for offset in range(leaderelectionList[index_1][0], leaderelectionList[index_1][1]):

            if '1022 received vote' in result[offset]:
                myId = result[offset][(result[offset].find(',from=')+6):(result[offset].find(', proposed leader'))]
                myState = result[offset][(result[offset].find(',state=')+7):(result[offset].find(',peerRpoch'))]
                dict['myId:' + str(myId)] = 'State:' + myState

            if '1022 leave FLE instance' in result[offset]:
                leaderId = result[offset][(result[offset].find('leader=')+7):(result[offset].find(', zxid'))]
                dict['myId:' + str(leaderId)] = 'State:LEADING'
                myId = result[offset][(result[offset].find('my id=')+6):(result[offset].find(', my state'))]
                myState = result[offset][(result[offset].find('my state=')+9):(len(result[offset]) -1)]
                dict['myId:' + str(myId)] = 'State:' + myState
        dict['myId:9999'] = 'State:LOOKING'
        for k,v in dict.items():
            stateconsistencyoutfile.write(k + ',' + v + '\n')
    stateconsistencyoutfile.close()

'''
brodcast output log parser
'''
def selectBrodCastLog(result,broadcastout):
    deleteFile(broadcastout)
    broadcastoutfile = open(broadcastout, 'w')
    broadcastlist = []
    broadcastlist2 = [0,0]
    for index in range(len(result)):
        if ('FollowerRequestProcessor' in result[index]) and ('1022 Processing request' in result[index]) and (' type:create ' in result[index]):
            broadcastlist2[0] = index
        if ('LeaderRequestProcessor' in result[index]) and ('1022 Leader Request process' in result[index]) and (' type:create ' in result[index]):
            broadcastlist2[0] = index

        if ('FinalRequestProcessor' in result[index]) and ('1022 Processing request to DataTree' in result[index]) and ('1022 leader received ack size from follower,ack' in result[index + 1]):
            broadcastlist2[1] = index +1
        if (broadcastlist2[1] > broadcastlist2[0]) and (broadcastlist2[0] >0):
            broadcastlist.append(broadcastlist2)
            broadcastlist2 = [0, 0]

    for index_1 in range(len(broadcastlist)):
        state = 0
        broadcastoutfile.write("state:0,myId:0,action:init,sessionid:0,type:0,cxid:0,zxidHigh:0,zxidLow:0,txntype:0,reqpath:0" + "\n")

        for temp in range(broadcastlist[index_1][0],broadcastlist[index_1][1]):


            if ('PrepRequestProcessor' in result[temp]) and ('1022 createRequest' in result[temp]):
                myId = result[temp][(result[temp].find("[myid:") + 6):(result[temp].find("[myid:") + 7)]
                action = "CreateRequest"
                sessionid = result[temp][(result[temp].find("=sessionid:") + 11):(result[temp].find(" type:"))]
                type = result[temp][(result[temp].find("type:") + 5):(result[temp].find(" cxid"))]
                cxid = result[temp][(result[temp].find("cxid:") + 5):(result[temp].find(" zxid"))]
                zxid = result[temp][(result[temp].find("zxid:") + 5):(result[temp].find(" txntype"))]
                txntype = result[temp][(result[temp].find("txntype:") + 8):(result[temp].find(" reqpath"))]
                reqpath = result[temp].strip().replace('\n', '')[(result[temp].strip().replace('\n', '').find("reqpath:") + 8):(len(result[temp].strip().replace('\n', '')))]
                state = state + 1
                zxidLow = eval("0x" + zxid[len(zxid) - 7:len(zxid)])
                zxidHigh = eval(zxid[:(len(zxid) - 8)])
                broadcastoutfile.write("state:" + str(
                    state) + ",myId:" + myId + ",action:" + action + ",sessionid:" + sessionid + ",type:" + type + ",cxid:" + cxid + ",zxidHigh:" + str(
                    zxidHigh) + ",zxidLow:" + str(zxidLow) + ",txntype:" + txntype + ",reqpath:" + reqpath + "\n")
            if ('Leader' in result[temp]) and ('1022 leader launch proposal' in result[temp]):
                myId = result[temp][(result[temp].find("[myid:") + 6):(result[temp].find("[myid:") + 7)]
                action = "LeaderLaunchProposal"
                sessionid = result[temp][(result[temp].find("sessionid:") + 10):(result[temp].find(" type:"))]
                type = result[temp][(result[temp].find("type:") + 5):(result[temp].find(" cxid"))]
                cxid = result[temp][(result[temp].find("cxid:") + 5):(result[temp].find(" zxid"))]
                zxid = result[temp][(result[temp].find("zxid:") + 5):(result[temp].find(" txntype"))]
                txntype = result[temp][(result[temp].find("txntype:") + 8):(result[temp].find(" reqpath"))]
                reqpath = result[temp][(result[temp].find("reqpath:") + 8):(result[temp].find(",zxid"))]
                state = state + 1
                zxidLow = eval("0x" + zxid[len(zxid) - 7:len(zxid)])
                zxidHigh = eval(zxid[:(len(zxid) - 8)])
                broadcastoutfile.write("state:" + str(
                    state) + ",myId:" + myId + ",action:" + action + ",sessionid:" + sessionid + ",type:" + type + ",cxid:" + cxid + ",zxidHigh:" + str(
                    zxidHigh) + ",zxidLow:" + str(zxidLow) + ",txntype:" + txntype + ",reqpath:" + reqpath + "\n")

            if '1022 received request from leader' in result[temp]:
                myId = result[temp][(result[temp].find("[myid:") + 6):(result[temp].find("[myid:") + 7)]
                action = "ReceivedProposal"
                sessionid = result[temp][(result[temp].find("=sessionid:") + 11):(result[temp].find(" type:"))]
                type = result[temp][(result[temp].find("type:") + 5):(result[temp].find(" cxid"))]
                cxid = result[temp][(result[temp].find("cxid:") + 5):(result[temp].find(" zxid"))]
                zxid = result[temp][(result[temp].find("zxid:") + 5):(result[temp].find(" txntype"))]
                txntype = result[temp][(result[temp].find("txntype:") + 8):(result[temp].find(" reqpath"))]
                reqpath = result[temp].strip().replace('\n', '')[(result[temp].strip().replace('\n', '').find("reqpath:") + 8):(len(result[temp].strip().replace('\n', '')))]
                state = state + 1
                zxidLow = eval("0x" + zxid[len(zxid) - 7:len(zxid)])
                zxidHigh = eval(zxid[:(len(zxid) - 8)])
                broadcastoutfile.write("state:" + str(
                    state) + ",myId:" + myId + ",action:" + action + ",sessionid:" + sessionid + ",type:" + type + ",cxid:" + cxid + ",zxidHigh:" + str(
                    zxidHigh) + ",zxidLow:" + str(zxidLow) + ",txntype:" + txntype + ",reqpath:" + reqpath + "\n")
            if ('SendAckRequestProcessor' in result[temp]) and ('1022 follower send ACK to leader' in result[temp]):
                myId = result[temp][(result[temp].find("[myid:") + 6):(result[temp].find("[myid:") + 7)]
                action = "FollowerSendAckToLeader"
                sessionid = "-1"
                type = result[temp][(result[temp].find("QuorumPacket=") + 13):(result[temp].find("QuorumPacket=")+14)]
                cxid = "-1"
                zxid = hex(int(result[temp][(result[temp].find("QuorumPacket=") + 15):(result[temp].find(",,v"))]))
                txntype = "-1"
                reqpath = "-1"
                state = state + 1
                zxidLow = eval("0x" + zxid[len(zxid) - 7:len(zxid)])
                zxidHigh = eval(zxid[:(len(zxid) - 8)])
                broadcastoutfile.write("state:" + str(
                    state) + ",myId:" + myId + ",action:" + action + ",sessionid:" + sessionid + ",type:" + type + ",cxid:" + cxid + ",zxidHigh:" + str(
                    zxidHigh) + ",zxidLow:" + str(zxidLow) + ",txntype:" + txntype + ",reqpath:" + reqpath + "\n")

            if ('LearnerHandler' in result[temp]) and ('1022 leader received ACK from follower' in result[temp]):
                myId = result[temp][(result[temp].find("[myid:") + 6):(result[temp].find("[myid:") + 7)]
                action = "LeaderReceivedAckFromFollower"
                sessionid = "-1"
                type = result[temp][(result[temp].find("qp=") + 3):(result[temp].find("qp=") + 4)]
                cxid = "-1"
                zxid = hex(int(result[temp][(result[temp].find("qp=") + 5):(result[temp].find(",,v"))]))
                txntype = "-1"
                reqpath = "-1"
                state = state + 1
                zxidLow = eval("0x" + zxid[len(zxid) - 7:len(zxid)])
                zxidHigh = eval(zxid[:(len(zxid) - 8)])
                broadcastoutfile.write("state:" + str(
                    state) + ",myId:" + myId + ",action:" + action + ",sessionid:" + sessionid + ",type:" + type + ",cxid:" + cxid + ",zxidHigh:" + str(
                    zxidHigh) + ",zxidLow:" + str(zxidLow) + ",txntype:" + txntype + ",reqpath:" + reqpath + "\n")

            if ('LearnerHandler' in result[temp]) and ('1022 send commit msg' in result[temp]):
                myId = result[temp][(result[temp].find("[myid:") + 6):(result[temp].find("[myid:") + 7)]
                action = "LeaderSendCommitMsg"
                sessionid = "-1"
                type = result[temp][(result[temp].find("qp=") + 3):(result[temp].find("qp=") + 4)]
                cxid = "-1"
                zxid = hex(int(result[temp][(result[temp].find("qp=") + 5):(result[temp].find(",,v"))]))
                txntype = "-1"
                reqpath = "-1"
                state = state + 1
                zxidLow = eval("0x" + zxid[len(zxid) - 7:len(zxid)])
                zxidHigh = eval(zxid[:(len(zxid) - 8)])
                broadcastoutfile.write("state:" + str(
                    state) + ",myId:" + myId + ",action:" + action + ",sessionid:" + sessionid + ",type:" + type + ",cxid:" + cxid + ",zxidHigh:" + str(
                    zxidHigh) + ",zxidLow:" + str(zxidLow) + ",txntype:" + txntype + ",reqpath:" + reqpath + "\n")

            if ('CommitProcessor' in result[temp]) and ('1022 Committing request' in result[temp]):
                myId = result[temp][(result[temp].find("[myid:") + 6):(result[temp].find("[myid:") + 7)]
                action = "CommitedRequest"
                sessionid = result[temp][(result[temp].find("sessionid:") + 10):(result[temp].find(" type:"))]
                type = result[temp][(result[temp].find("type:") + 5):(result[temp].find(" cxid"))]
                cxid = result[temp][(result[temp].find("cxid:") + 5):(result[temp].find(" zxid"))]
                zxid = result[temp][(result[temp].find("zxid:") + 5):(result[temp].find(" txntype"))]
                txntype = result[temp][(result[temp].find("txntype:") + 8):(result[temp].find(" reqpath"))]
                reqpath = result[temp].strip().replace('\n', '')[
                          (result[temp].strip().replace('\n', '').find("reqpath:") + 8):(
                              len(result[temp].strip().replace('\n', '')))]
                state = state + 1
                zxidLow = eval("0x" + zxid[len(zxid) - 7:len(zxid)])
                zxidHigh = eval(zxid[:(len(zxid) - 8)])
                broadcastoutfile.write("state:" + str(
                    state) + ",myId:" + myId + ",action:" + action + ",sessionid:" + sessionid + ",type:" + type + ",cxid:" + cxid + ",zxidHigh:" + str(
                    zxidHigh) + ",zxidLow:" + str(zxidLow) + ",txntype:" + txntype + ",reqpath:" + reqpath + "\n")

            if ('FinalRequestProcessor' in result[temp]) and ('1022 Processing request to DataTree' in result[temp]):
                myId = result[temp][(result[temp].find("[myid:") + 6):(result[temp].find("[myid:") + 7)]
                action = "Request2DataTree"
                sessionid = result[temp][(result[temp].find("sessionid:") + 10):(result[temp].find(" type:"))]
                type = result[temp][(result[temp].find("type:") + 5):(result[temp].find(" cxid"))]
                cxid = result[temp][(result[temp].find("cxid:") + 5):(result[temp].find(" zxid"))]
                zxid = result[temp][(result[temp].find("zxid:") + 5):(result[temp].find(" txntype"))]
                txntype = result[temp][(result[temp].find("txntype:") + 8):(result[temp].find(" reqpath"))]
                reqpath = result[temp].strip().replace('\n', '')[
                          (result[temp].strip().replace('\n', '').find("reqpath:") + 8):(
                              len(result[temp].strip().replace('\n', '')))]
                state = state + 1
                zxidLow = eval("0x" + zxid[len(zxid) - 7:len(zxid)])
                zxidHigh = eval(zxid[:(len(zxid) - 8)])
                broadcastoutfile.write("state:" + str(
                    state) + ",myId:" + myId + ",action:" + action + ",sessionid:" + sessionid + ",type:" + type + ",cxid:" + cxid + ",zxidHigh:" + str(
                    zxidHigh) + ",zxidLow:" + str(zxidLow) + ",txntype:" + txntype + ",reqpath:" + reqpath + "\n")

        broadcastoutfile.write("state:999999,myId:9999,action:end,sessionid:0,type:0,cxid:0,zxidHigh:0,zxidLow:0,txntype:0,reqpath:0" +"\n")
    broadcastoutfile.close()
'''
选举日志输出
'''
def slectLeaderSelection(leaderelectionout,result):
    deleteFile(leaderelectionout)
    leaderelectionoutfile = open(leaderelectionout, 'w')
    leaderelectionList = []
    leaderelectionList2 = [0, 0]
    for index in range(len(result)):
        if '1022 follower sync data' in result[index]:
            leaderelectionList2[0] = index
        elif '1022 follower send epoch' in result[index]:
            leaderelectionList2[1] = index
        if leaderelectionList2[1] > leaderelectionList2[0]:
            leaderelectionList.append(leaderelectionList2)
            leaderelectionList2 = [0,0]

        # leader选举日志解析
    for index_1 in range(len(leaderelectionList)):
        myidlist = []
        for offset in range(leaderelectionList[index_1][0], leaderelectionList[index_1][1]):
            if '1022 end vote:' in result[offset]:
                myid = result[offset][(result[offset].find('[myid:') + 6):(result[offset].find('[myid:') + 7)]
                endvotetemp = result[offset][(result[offset].find('end vote: (') + 11):(result[offset].find('end vote: (') + 12)]
                myidlist.append(str(myid) + '--' + str(endvotetemp))
        for offset2 in range(len(myidlist)):
            leaderelectionoutfile.write(("myId:0,myState:init,from:0,proposedLeader:0,proposedZxidHigh:0,proposedZxidLow:0,electionEpoch:0,state:init,peerRpoch:0,endvote:0").strip() + "\n")
            for offset3 in range(leaderelectionList[index_1][0], leaderelectionList[index_1][1]):
                myidTemp = result[offset3][(result[offset3].find('[myid:') + 6):(result[offset3].find('[myid:') + 7)]
                if (int(myidlist[offset2].split('--')[0]) == int(myidTemp)) and ( '1022 received vote' in result[offset3]):
                    temp = result[offset3].strip().replace('\n', '')
                    myId = myidlist[offset2].split('--')[0]
                    myState = temp[(temp.find('my state=') + 9):(temp.find(',from'))]
                    from2 = temp[(temp.find(',from=') + 6):(temp.find(', proposed leader'))]
                    proposedLeader = temp[(temp.find('proposed leader=') + 16):(temp.find(', proposed zxid'))]
                    # proposed leader=3, proposed zxid=0x100000006,
                    proposedZxid =temp[(temp.find('proposed zxid=') + 14):(temp.find(', proposed election epoch'))]
                    if (eval(proposedZxid) == 0):
                        proposedZxidLow = 0
                        proposedZxidHigh = 0
                    else:
                        proposedZxidLow = eval("0x" + temp[(temp.find(', proposed election epoch')-7):(temp.find(', proposed election epoch'))])
                        proposedZxidHigh = eval(temp[(temp.find('proposed zxid=') + 14):(temp.find(', proposed election epoch')-8)])
                    electionEpoch = eval(temp[(temp.find('proposed election epoch=') + 24):(temp.find(',state'))])
                    state = temp[(temp.find(',state=') + 7):(temp.find(',peerRpoch'))]
                    peerRpoch = temp[(len(temp) - 1):(len(temp))]
                    endvote = myidlist[offset2].split('--')[1]
                    leaderelectionoutfile.write(("myId:"+myId+",myState:"+myState+",from:"+from2+",proposedLeader:"+proposedLeader+
                              ",proposedZxidHigh:"+str(proposedZxidHigh)+",proposedZxidLow:"+str(proposedZxidLow)+",electionEpoch:"+str(electionEpoch)+",state:"+state+
                              ",peerRpoch:"+peerRpoch+",endvote:"+endvote).strip() + "\n")
            leaderelectionoutfile.write(("myId:9999999,myState:init,from:0,proposedLeader:0,proposedZxidHigh:0,proposedZxidLow:0,electionEpoch:0,state:end,peerRpoch:0,endvote:0").strip() + "\n")

    leaderelectionoutfile.close()



"""
This is a log parser function.
Parameters:
  result - label data
  connectout - 建链输出
  voteout - 选举输出
  sycdataout - 数据同步输出
"""
def logparser(result,connectout,sycdataout):
    deleteFile(connectout)
    deleteFile(sycdataout)
    connectoutfile = open(connectout,'w')
    sycdataoutfile = open(sycdataout,'w')
    syncdataList = []
    syncdataList2 = [0,0]
    for index in range(len(result)):
        if '1022:connection:' in result[index]:
            connectoutfile.write(result[index][(result[index].find('(') +1):(result[index].find(')'))].replace(' --> ',',').strip()+"\n")
        elif '1022 follower send epoch' in result[index]:
            syncdataList2[0]=index
        elif '1022 follower sync data' in result[index]:
            syncdataList2[1]=index
        if syncdataList2[0] != 0 and syncdataList2[1] != 0 and syncdataList2[0] < syncdataList2[1]:
            syncdataList.append(syncdataList2)
            syncdataList2 = [0,0]

    #数据同步日志解析

    for index2 in range(len(syncdataList)):
        follower = ''
        followerSendEpochToLeader = ''
        leader = ''
        leaderReceivedEpochFromFollower = ''
        leaderCalculaterNewEpoch = ''
        followerReceivedNewEpochFromLeader = ''
        leaderSyncDataZxid = ''
        followerSyncDataZxid = ''
        for j in range(syncdataList[index2][0],syncdataList[index2][1]+1):

            if '1022 follower send epoch' in result[j]:
                follower = result[j][(result[j].find('[myid:')+6):(result[j].find('[myid:') + 7)]
                temp = result[j].strip().replace('\n','');
                followerSendEpochToLeader = temp[len(temp)-1:len(temp)]

            elif '1022 leader recived follower epoch' in result[j]:
                leader = result[j][(result[j].find('[myid:')+6):(result[j].find('[myid:')+7)]
                temp = result[j].strip().replace('\n', '');
                leaderReceivedEpochFromFollower = temp[len(temp)-1:len(temp)]
            elif '1022 leader calculate follower newEpoch' in result[j]:
                temp = result[j].strip().replace('\n', '');
                leaderCalculaterNewEpoch = temp[len(temp)-1:len(temp)]
            elif '1022 follower received leader newEpoch' in result[j]:
                temp = result[j].strip().replace('\n', '');
                followerReceivedNewEpochFromLeader = temp[len(temp)-1:len(temp)]
            elif '1022 leader sync data,zxid' in result[j]:
                leaderSyncDataZxid ="0x" +result[j][(result[j].find('zxid')+5):(result[j].find(',data'))]
            elif '1022 follower sync data,zxid' in result[j]:
                followerSyncDataZxid ="0x" +result[j][(result[j].find('zxid')+5):(len(result[j]))]

        sycdataoutfile.write(("leader:"+leader+",follower:"+follower+",followerSendEpochToLeader:"+followerSendEpochToLeader+
              ",leaderReceivedEpochFromFollower:"+leaderReceivedEpochFromFollower+",leaderCalculaterNewEpoch:"+leaderCalculaterNewEpoch+
              ",followerReceivedNewEpochFromLeader:"+followerReceivedNewEpochFromLeader+",leaderSyncDataZxid:"+str(leaderSyncDataZxid)+
              ",followerSyncDataZxid:"+str(followerSyncDataZxid)).strip()+"\n")

    connectoutfile.close()
    sycdataoutfile.close()

def deleteFile(filePath):
    if os.path.exists(filePath):
        os.remove(filePath)

def selectsnaprequest(result,snapfilesync):
    deleteFile(snapfilesync)
    snapsyncfile = open(snapfilesync, 'w')
    snaplist = []
    myIddlist = []
    for index in range(len(result)):
        if '1022 request snap file' in result[index]:
            myId = result[index][(result[index].find('[myid:') + 6):(result[index].find('[myid:') + 7)]
            myIddlist.append("myId:"+myId)
            sessionid = result[index][(result[index].find('sessionid:')+10):(result[index].find(' type'))]
            cxid = result[index][(result[index].find('cxid:')+5):(result[index].find(' zxid'))]
            zxid = result[index][(result[index].find('zxid:')+5):(result[index].find(' txntype'))]
            snaplist.append("myId:" + myId +",sessionid:" + sessionid + ",cxid:" + cxid +",zxid:" + zxid + "\n")

    myIddlist2 = list(set(myIddlist))
    for index in range(len(myIddlist2)):
        for index2 in range(len(snaplist)):
            if myIddlist2[index] in snaplist[index2]:
                snapsyncfile.write(snaplist[index2])
    snapsyncfile.close()


def runVerification():
    os.chdir("/media/vdc/software/tlazookeeper/verification")
    os.system("/media/vdc/software/jdk-11.0.7/bin/java -jar tla2tools.jar -config Zookeeper.cfg -cleanup -deadlock Zookeeper.tla")


if __name__ == '__main__':
    result = fileReadZookeeperLog('/media/vdc/software/tlazookeeper/zookeeper/logs/zookeeper-root-server-LIN-4CB71BF7AE3.zte.intra.log')
    logparser(result,'/media/vdc/software/tlazookeeper/verification/connect.log','/media/vdc/software/tlazookeeper/verification/datasync.log')
    slectLeaderSelection('/media/vdc/software/tlazookeeper/verification/leaderelection.log',selectQuorumPeerLog(result))
    selectZookeeperState(selectQuorumPeerLog(result),'/media/vdc/software/tlazookeeper/verification/stateconsistency.log')
    selectsnaprequest(result, '/media/vdc/software/tlazookeeper/verification/snapfilesync.log')
    selectBrodCastLog(result,'/media/vdc/software/tlazookeeper/verification/broadcast.log')
    runVerification()

    #print(hex(4294967298))  0x100000002


