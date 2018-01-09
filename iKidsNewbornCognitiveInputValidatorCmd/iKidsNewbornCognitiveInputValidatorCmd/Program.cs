using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace iKidsNewbornCognitiveInputValidatorCmd
{
    class Program
    {
        enum Option { KeyAndXBox, KeyAndTCP, XBoxAndTCP, All };
        static void Main(string[] args)
        {
            Dictionary<int, Tuple<int, int>> output = new Dictionary<int, Tuple<int, int>>();
            Option selectedOption = Option.KeyAndXBox;
            if (args.Length != 3)
            {
                Console.WriteLine("Error: must have 3 arguments (input log file, state log file, output file).");
                return;
            }
            if (args.Length > 3)
            {
                switch (args[3])
                {
                    case "kx":
                        selectedOption = Option.KeyAndXBox;
                        break;
                    case "kt":
                        selectedOption = Option.KeyAndTCP;
                        break;
                    case "xt":
                        selectedOption = Option.XBoxAndTCP;
                        break;
                    case "all":
                        selectedOption = Option.All;
                        break;
                }
            }
            if (!File.Exists(args[0]))
            {
                Console.WriteLine("Error: " + args[0] + " not found.");
                return;
            }
            if (!File.Exists(args[1]))
            {
                Console.WriteLine("Error: " + args[1] + " not found.");
                return;
            }
            try
            {
                StreamReader reader = new StreamReader(args[0]);
                string inputString = reader.ReadToEnd();
                reader.Close();
                string[] lines = inputString.Split(new string[] { "\r\n" }, StringSplitOptions.RemoveEmptyEntries);
                float[] times = new float[lines.Length / 3];
                string[] keyCmds = new string[lines.Length / 3];
                string[] xboxCmds = new string[lines.Length / 3];
                string[] tcpCmds = new string[lines.Length / 3];
                int count = 0;
                for (int i = 0; i < lines.Length; i++)
                {
                    if (lines[i].Trim() == "") continue;
                    string[] splitLine = lines[i].Split(new char[] { ':' });
                    float time = float.Parse(splitLine[0]);
                    if (splitLine[1].Trim() == "Keyboard Commands")
                    {
                        keyCmds[count] = splitLine[2];
                        times[count] = time;
                    }
                    if (splitLine[1].Trim() == "XBox Controller Commands")
                        xboxCmds[count] = splitLine[2];
                    if (splitLine[1].Trim() == "TCP Commands")
                    {
                        tcpCmds[count] = splitLine[2];
                        count++;
                    }

                }
                reader = new StreamReader(args[1]);
                string stateString = reader.ReadToEnd();
                reader.Close();
                lines = stateString.Split(new string[] { "\r\n" }, StringSplitOptions.RemoveEmptyEntries);
                int[] states = new int[times.Length];
                float[] stateTimes = new float[times.Length];
                count = 0;
                for (int i = 0; i < lines.Length; i++)
                {
                    string[] splitLine = lines[i].Split(new char[] { ':' });
                    if (splitLine[1].Trim().Equals("Current Task Index"))
                    {
                        states[count] = int.Parse(splitLine[2]);
                        stateTimes[count] = float.Parse(splitLine[0]);
                        count++;
                    }
                }

                bool match = true;
                for (int i = 0; i < times.Length; i++)
                    if (times[i] != stateTimes[i])
                    {
                        match = false;
                        Console.WriteLine(i);
                        break;
                    }
                if (!match)
                {
                    Console.WriteLine("Error: sync problem between input and state log file. Time stamps don't match, are you sure they're matching logs?");
                    return;
                }
                int startIndex = 0;
                for (int i = 0; i < times.Length; i++)
                    if (states[i] == 2)
                    {
                        startIndex = i;
                        break;
                    }
                for (int i = startIndex; i < times.Length; i++)
                {
                    Tuple<int, int> val = new Tuple<int, int>(0, 0);
                    if (output.ContainsKey(states[i]))
                        output.TryGetValue(states[i], out val);
                    else
                        output.Add(states[i], val);
                    switch (selectedOption)
                    {
                        case Option.KeyAndXBox:
                            if (keyCmds[i].Trim().Equals(xboxCmds[i].Trim()))
                                val = new Tuple<int, int>(val.Item1 + 1, val.Item2);
                            else
                                val = new Tuple<int, int>(val.Item1, val.Item2 + 1);
                            break;
                        case Option.KeyAndTCP:
                            if (keyCmds[i].Trim().Equals(tcpCmds[i].Trim()))
                                val = new Tuple<int, int>(val.Item1 + 1, val.Item2);
                            else
                                val = new Tuple<int, int>(val.Item1, val.Item2 + 1);
                            break;
                        case Option.XBoxAndTCP:
                            if (xboxCmds[i].Trim().Equals(tcpCmds[i].Trim()))
                                val = new Tuple<int, int>(val.Item1 + 1, val.Item2);
                            else
                                val = new Tuple<int, int>(val.Item1, val.Item2 + 1);
                            break;
                        case Option.All:
                            if (keyCmds[i].Trim().Equals(xboxCmds[i].Trim()) && keyCmds[i].Trim().Equals(tcpCmds[i].Trim()))
                                val = new Tuple<int, int>(val.Item1 + 1, val.Item2);
                            else
                                val = new Tuple<int, int>(val.Item1, val.Item2 + 1);
                            break;
                    }
                    output[states[i]] = val;
                }
            }
            catch (Exception)
            {
                Console.WriteLine("Error: problem reading input files.");
                return;
            }
            try
            {
                StreamWriter writer = new StreamWriter(args[2]);
                writer.WriteLine("StateNum,MatchCount,MismatchCount,MatchProportion");
                foreach (KeyValuePair<int, Tuple<int, int>> entry in output)
                    writer.WriteLine(entry.Key + "," + entry.Value.Item1 + "," + entry.Value.Item2 + "," + ((double)entry.Value.Item1 / ((double)entry.Value.Item1 + (double)entry.Value.Item2)));
                writer.Close();
            }
            catch (Exception)
            {
                Console.WriteLine("Error: problem creating/saving to output file.");
                return;
            }
        }
    }
}
