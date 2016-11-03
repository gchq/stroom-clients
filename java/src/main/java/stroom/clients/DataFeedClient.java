package stroom.clients;
import java.io.File;
import java.io.FileInputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.HashMap;
import java.util.zip.GZIPOutputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import javax.net.ssl.HttpsURLConnection;

/**
 * <p>Runnable Java Program that can act as a test client to the data feed.</p>
 */
public final class DataFeedClient {
    private static final String ARG_URL = "url";
    private static final String ARG_INPUTFILE = "inputfile";
    private static final String ARG_COMPRESSION = "compression";
    private static final String ARG_INPUT_COMPRESSION = "inputcompression";
    private static final String ZIP = "zip";
    private static final String GZIP = "gzip";

    private static final int BUFFER_SIZE = 1024;

    private DataFeedClient() {
        // Private constructor.
    }

    /**
     * @param args program args
     */
    public static void main(final String[] args) {
        try {

            HashMap<String, String> argsMap = new HashMap<>();
            for (int i = 0; i < args.length; i++) {
                String[] split = args[i].split("=");
                if (split.length > 1) {
                    argsMap.put(split[0], split[1]);
                } else {
                    argsMap.put(split[0], "");
                }
            }

            String urlS = argsMap.get(ARG_URL);
            String inputFileS = argsMap.get(ARG_INPUTFILE);

            long startTime = System.currentTimeMillis();

            System.out.println("Using url=" + urlS + " and inputFile=" + inputFileS);

            File inputFile = new File(inputFileS);

            URL url = new URL(urlS);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();

            if (connection instanceof HttpsURLConnection) {
                ((HttpsURLConnection) connection).setHostnameVerifier((arg0, arg1) -> {
                    System.out.println("HostnameVerifier - " + arg0);
                    return true;
                });
            }
            connection.setRequestMethod("POST");
            connection.setRequestProperty("Content-Length", "" + inputFile.length());
            connection.setRequestProperty("Content-Type", "application/audit");
            connection.setDoOutput(true);
            connection.setDoInput(true);

            // Also add all our command options
            for (String arg : argsMap.keySet()) {
                connection.addRequestProperty(arg, argsMap.get(arg));
            }

            // Here we allow for the input file already being compressed
            if (argsMap.containsKey(ARG_INPUT_COMPRESSION)) {
                connection.addRequestProperty(ARG_COMPRESSION, argsMap.get(ARG_INPUT_COMPRESSION));
            }


            connection.connect();

            FileInputStream fis = new FileInputStream(inputFile);
            OutputStream out = connection.getOutputStream();
            // Using Zip Compression we just have 1 file (called 1)
            if (ZIP.equalsIgnoreCase(argsMap.get(ARG_COMPRESSION))) {
                ZipOutputStream zout = new ZipOutputStream(out);
                zout.putNextEntry(new ZipEntry("1"));
                out = zout;
                System.out.println("Using ZIP");
            }
            if (GZIP.equalsIgnoreCase(argsMap.get(ARG_COMPRESSION))) {
                out = new GZIPOutputStream(out);
                System.out.println("Using GZIP");
            }


            // Write the output
            byte[] buffer = new byte[BUFFER_SIZE];
            int readSize;
            while ((readSize = fis.read(buffer)) != -1) {
                out.write(buffer, 0, readSize);
            }

            out.flush();
            out.close();
            fis.close();

            int response =  connection.getResponseCode();
            String msg = connection.getResponseMessage();

            connection.disconnect();

            System.out.println("Client Got Response " + response + " in " + (System.currentTimeMillis() - startTime) + "ms");
            if (msg != null && msg.length() > 0) {
                System.out.println(msg);
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }
}
