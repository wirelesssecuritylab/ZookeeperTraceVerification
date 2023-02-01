import tlc2.value.impl.*;
import util.UniqueString;

import java.io.*;
import java.util.*;


public class ExternalSeqRecordParser2 {
	// @TLAPlusOperator(identifier = "ExSeqRcdParser2", module = "ExternalSeqRecordParser2")
	public static Value ExSeqRcdParser2(final StringValue absolutePath) throws IOException {
		// read the log file at [absolutePath]
		BufferedReader br = new BufferedReader(new FileReader(absolutePath.val.toString()));
		// initialize array for all parsed records
		List<RecordValue> rcdSeq = new ArrayList<>();
		try {
			String line = br.readLine();
			while (line != null) {
				// initialize arrays for field values [fields] and [values]
				List<UniqueString> fields = new ArrayList<>();
				List<Value> values = new ArrayList<>();
				// split string on seperator into array of filed and value
				String[] lnarr = line.split(",");
				// parse each entry of [lnarr] as a field-value pair
				for (int i = 0; i < lnarr.length; i++) {
					parsePair(lnarr[i].split(":"), fields, values);
				}
				
				//leader:3,follower:2,followerSendEpochToLeader:1,leaderReceivedEpochFromFollower:1,leaderCalculaterNewEpoch:2,followerReceivedNewEpochFromLeader:2,leaderSyncDataZxid:10000006,followerSyncDataZxid:10000006

				// add record to the sequence
				rcdSeq.add(new RecordValue(fields.toArray(new UniqueString[0]), values.toArray(new Value[0]), true));
				line = br.readLine();
			}
		} finally {
			br.close();
		}
		// return the aggregated sequence of records
		return new TupleValue(rcdSeq.toArray(new Value[0]));
	}

	private static void parsePair(String[] pair, List<UniqueString> fields, List<Value> values) {
		fields.add(UniqueString.uniqueStringOf(pair[0]));
		
		if (pair[1].contains("0x")) {
			values.add(new StringValue(pair[1]));
		}else {
			values.add(IntValue.gen(Integer.parseInt(pair[1])));
		}

	}	

}
