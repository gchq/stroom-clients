package stroom.clients;

import java.io.ByteArrayInputStream;
import java.io.DataInputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.security.KeyFactory;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.cert.Certificate;
import java.security.cert.CertificateFactory;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Collection;
import java.util.HashMap;

/**
 * <p>Class used to import keys from openssl into a java key store.</p>
 *
 * E.g.
 *
 * <code>
 * # Server
 * export SERVER=example
 *
 * # Gen Private Key
 * openssl genrsa -des3 -out $SERVER.key 1024
 *
 * # Gen CSR
 * openssl req -new -key $SERVER.key -out $SERVER.csr
 *
 * # Copy CSR then Create Cert (cat then paste contents from CA)
 * cat $SERVER.csr
 * vi $SERVER.crt
 *
 * # Create DER format Keys
 * openssl pkcs8 -topk8 -nocrypt -in $SERVER.key -inform PEM -out $SERVER.key.der -outform DER
 * openssl x509 -in $SERVER.crt -inform PEM -out $SERVER.crt.der -outform DER
 *
 * # Now Import the Key using this tool
 * java ImportKey keystore=$SERVER.jks keypass=$SERVER alias=$SERVER keyfile=$SERVER.key.der certfile=$SERVER.crt.der
 *
 * # Also inport the CA if required
 * keytool -import -alias CA -file root_ca.crt -keystore $SERVER.jks -storepass $SERVER
 *
 * # List contents at end
 * keytool -list -keystore $SERVER.jks -storepass $SERVER
 * </code>
 */
public final class ImportKey {

    private ImportKey() {
        // NA Utility class
    }

    /**
     * Utility Method
     */
    private static InputStream fullStream(final String fname) throws IOException {
        FileInputStream fis = new FileInputStream(fname);
        DataInputStream dis = new DataInputStream(fis);
        byte[] bytes = new byte[dis.available()];
        dis.readFully(bytes);
        ByteArrayInputStream bais = new ByteArrayInputStream(bytes);
        return bais;
    }

    /**
     * main program.
     *
     * @param args cmd args
     */
    @SuppressWarnings("unchecked")
    public static void main(final String[] args) {

        HashMap<String, String> argsMap = new HashMap<>();
        for (int i = 0; i < args.length; i++) {
            String[] split = args[i].split("=");
            if (split.length > 1) {
                argsMap.put(split[0], split[1]);
            } else {
                argsMap.put(split[0], "");
            }
        }

        String keyPass = argsMap.get("keypass");
        String alias = argsMap.get("alias");
        String keystore = argsMap.get("keystore");
        String keyfile = argsMap.get("keyfile");
        String certfile = argsMap.get("certfile");


        try {
            KeyStore ks = KeyStore.getInstance("JKS", "SUN");
            ks.load(null, keyPass.toCharArray());
            ks.store(new FileOutputStream(keystore), keyPass.toCharArray());
            ks.load(new FileInputStream(keystore), keyPass.toCharArray());

            InputStream f1 = fullStream(keyfile);
            byte[] key = new byte[f1.available()];
            KeyFactory kf = KeyFactory.getInstance("RSA");
            f1.read(key, 0, f1.available());
            f1.close();

            PKCS8EncodedKeySpec keysp = new PKCS8EncodedKeySpec(key);
            PrivateKey ff = kf.generatePrivate(keysp);

            CertificateFactory cf = CertificateFactory.getInstance("X.509");
            InputStream certStream = fullStream(certfile);

            Collection c = cf.generateCertificates(certStream);
            Certificate[] certs = new Certificate[c.toArray().length];

            if (c.size() == 1) {
                certStream = fullStream(certfile);
                System.out.println("One certificate, no chain");
                Certificate cert = cf.generateCertificate(certStream);

                certs[0] = cert;
            } else {
                System.out.println("Certificate chain length: " + c.size());
                certs = (Certificate[]) c.toArray();
            }

            ks.setKeyEntry(alias, ff, keyPass.toCharArray(), certs);
            ks.store(new FileOutputStream(keystore), keyPass.toCharArray());


        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }

}
