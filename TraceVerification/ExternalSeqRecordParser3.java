import tlc2.value.impl.*;
import util.UniqueString;

import java.io.*;
import java.util.*;
import java.util.regex.Pattern;


public class ExternalSeqRecordParser3 {
	// @TLAPlusOperator(identifier = "ExSeqRcdParser3", module = "ExternalSeqRecordParser3")
	public static Value ExSeqRcdParser3(final StringValue absolutePath) throws IOException {
		// read the log file at [absolutePath]
		BufferedReader br = new BufferedReader(new FileReader(absolutePath.val.toString()));
		// initialize array for all parsed records
		List<TupleValue> result = new ArrayList<>();
		boolean flag = false;
		try {
			List<RecordValue> rcdSeq = new ArrayList<>();
			String line = br.readLine();
			while (line != null) {
				// parse each entry of [lnarr] as a field-value pair
				//myId:0,myState:init,from:0,proposedLeader:0,proposedZxid:0,electionEpoch:0,state:init,peerRpoch:0,endvote:0
				//myId:1,myState:LOOKING,from:1,proposedLeader:1,proposedZxid:0,electionEpoch:17,state:LOOKING,peerRpoch:0,endvote:2
				//myId:1,myState:LOOKING,from:2,proposedLeader:2,proposedZxid:0,electionEpoch:17,state:LOOKING,peerRpoch:0,endvote:2
				//myId:1,myState:LOOKING,from:1,proposedLeader:2,proposedZxid:0,electionEpoch:17,state:LOOKING,peerRpoch:0,endvote:2
				//myId:9999999,myState:init,from:0,proposedLeader:0,proposedZxid:0,electionEpoch:0,state:end,peerRpoch:0,endvote:0
				// split string on seperator into array of filed and value
				String[] lnarr = line.split(",");
				if (Integer.parseInt(lnarr[0].split(":")[1]) == 0) {
					flag = true;
					
				}else if (Integer.parseInt(lnarr[0].split(":")[1]) == 9999999) {
					flag = false;
				}else {
					if (flag) {
						// initialize arrays for field values [fields] and [values]
						List<UniqueString> fields = new ArrayList<>();
						List<Value> values = new ArrayList<>();
						for (int i = 0; i < lnarr.length; i++) {
							parsePair(lnarr[i].split(":"), fields, values);
						}
						rcdSeq.add(new RecordValue(fields.toArray(new UniqueString[0]), values.toArray(new Value[0]), true));
					}
				}
				if (!flag) {
					result.add(new TupleValue(rcdSeq.toArray(new Value[0])));
					rcdSeq.clear();
				}
				line = br.readLine();
			}
		} finally {
			br.close();
		}
		// return the aggregated sequence of records
		//return new TupleValue(rcdSeq.toArray(new Value[0]));
		return new TupleValue(result.toArray(new Value[0]));
	}

	private static void parsePair(String[] pair, List<UniqueString> fields, List<Value> values) {
		fields.add(UniqueString.uniqueStringOf(pair[0]));
		if (Pattern.compile("[0-9]*").matcher(pair[1]).matches()) {
			values.add(IntValue.gen(Integer.parseInt(pair[1])));
		}else {
			values.add(new StringValue(pair[1]));
		}
		
	}
}
