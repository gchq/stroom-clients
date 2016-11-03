using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Text;

namespace stroomclient
{
	public class HttpTest
	{
		private const string ARG_URL = "url";
		private const string ARG_INPUTFILE = "inputfile";

		private const int BUFFER_SIZE = 1024;

		public static void Main(string[] args)
		{
			Dictionary<string, string> argsMap = new Dictionary<string, string>();
			foreach (string arg in args)
			{
				string[] split = arg.Split(new char[]{'='});
				if (split.Length > 1) argsMap.Add(split[0], split[1]);
				else argsMap.Add(split[0], "");
			}

			HttpWebRequest request = (HttpWebRequest)WebRequest.Create(argsMap[ARG_URL]);
			request.Method = "POST";
			request.KeepAlive = false;
			request.ProtocolVersion = HttpVersion.Version11;
			request.ContentType = "application/audit";

			foreach (KeyValuePair<string,string> arg in argsMap)
			{
				//TODO: filter out some args?
				request.Headers.Add(arg.Key, arg.Value);
			}

			using (FileStream fis = File.OpenRead(argsMap[ARG_INPUTFILE]))
			{
				request.ContentLength = fis.Length;

				using (Stream requestStream = request.GetRequestStream())
				{				
					byte[] buffer = new byte[BUFFER_SIZE];
					int readSize;
					while ((readSize = fis.Read(buffer, 0, buffer.Length)) != 0)
					{
						requestStream.Write(buffer, 0, readSize);
					}
				}
			}

			HttpWebResponse response = null;
			try
			{
				response = (HttpWebResponse)request.GetResponse();
			}
			catch (WebException e)
			{
				response = (HttpWebResponse)e.Response;
			}

			if (response != null)
			{
				Console.WriteLine("Response code: " + response.StatusCode);

				using (Stream responseStream = response.GetResponseStream())
				{
					string responseStr = new StreamReader(responseStream).ReadToEnd();
					Console.WriteLine("Response:");
					Console.WriteLine(responseStr);
				}
			}
		}
	}
}
