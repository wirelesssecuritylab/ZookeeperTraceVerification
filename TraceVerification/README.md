1.使用javac编译TLC自定义算子为class文件<br/>
  javac -cp tla2tools.jar Broadcast.java<br/>
  javac -cp tla2tools.jar Broadcast2.java<br/>
  javac -cp tla2tools.jar ExternalSeqRecordParser2.java<br/>
  javac -cp tla2tools.jar ExternalSeqRecordParser3.java<br/>
  javac -cp tla2tools.jar StatesConsistencyInspect.java<br/>
  
2.使用python3运行main.py或者zookeeper.py，注意请修改main方法zookeeper的日志文件和采集到的trace文件的存储位置<br/>

  
