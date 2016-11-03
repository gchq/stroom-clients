package stroom.clients;
import java.io.FileInputStream;
import java.security.Key;
import java.security.KeyStore;
import java.util.HashMap;

import org.apache.commons.codec.binary.Base64;

/**
 * Utility to export a private key and certificate from a key store.
 *
 * E.g. java stroom.util.ExportKey
 * keystore=<HOME>/keys/server.keystore keypass=changeit alias=key
 */
public class ExportKey {
    public static void main(String[] args) throws Exception {
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

        KeyStore ks = KeyStore.getInstance("JKS", "SUN");
        ks.load(new FileInputStream(keystore), keyPass.toCharArray());

        Key key = ks.getKey(alias, keyPass.toCharArray());

        if (key == null) {
            System.out.println("No key with alias " + alias);
            return;
        }

        System.out.println("-----BEGIN PRIVATE KEY-----");
        System.out.println(new Base64().encode(key.getEncoded()));
        System.out.println("-----END PRIVATE KEY-----");

        System.out.println("-----BEGIN CERTIFICATE-----");
        System.out.println(new Base64().encode(ks.getCertificate(alias).getEncoded()));
        System.out.println("-----END CERTIFICATE-----");

    }
}
