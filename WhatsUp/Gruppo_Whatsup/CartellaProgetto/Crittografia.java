
package example;

import java.io.*;
import java.security.*;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;

import jolie.runtime.ByteArray;
import jolie.runtime.Value;
import jolie.runtime.JavaService;

import javax.crypto.*;
import javax.crypto.spec.SecretKeySpec;


public class Crittografia extends JavaService {


    //metodo che genera un paio di chiavi utilizzando l'algotitmo RSA
    public static Value keyGenerator() {
        //creo un value da restituire in output in Jolie
        Value valueGenerator = Value.create();
        try {
            //genero paio di chiavi
            KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
            generator.initialize(2048);
            KeyPair pairGenerator = generator.generateKeyPair();
            //dal paio estraggo una chiave pubblica e una privata
            byte[] publicKeyArray = pairGenerator.getPublic().getEncoded();
            ByteArray publicKey = new ByteArray(publicKeyArray);
            byte[] privateKeyArray = pairGenerator.getPrivate().getEncoded();
            ByteArray privateKey = new ByteArray(privateKeyArray);
            //assegno le chiavi in due rami del value che restituisco in output
            valueGenerator.getFirstChild("chiave_pubblica").setValue(publicKey);
            valueGenerator.getFirstChild("chiave_privata").setValue(privateKey);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return valueGenerator;
    }


    //metodo che codifica un messaggio attraverso una chiave pubblica
    public static Value encryption(Value inputValue) {
        //estraggo dal value ricevuto in input il messaggio da cifrare e la chiave pubblica da usare
        ByteArray publicKey = inputValue.getFirstChild("chiave_pubblica").byteArrayValue();
        byte[] publicKeyArray = publicKey.getBytes();
        String message = inputValue.getFirstChild("messaggio").strValue();
        byte[] messageArray = message.getBytes();
        //creo value per l'output
        Value valueEncryption = Value.create();
        try {
            //creo un oggetto PublicKey che abbia come valori la chiave pubblica presa in input
            KeyFactory keyFactor = KeyFactory.getInstance("RSA");
            PublicKey pubKey = keyFactor.generatePublic(new X509EncodedKeySpec(publicKeyArray));
            //codifico attraverso la libreria Cipher
            Cipher cipher = Cipher.getInstance("RSA");
            cipher.init(Cipher.ENCRYPT_MODE, pubKey);
            byte[] encryptedMessageArray = cipher.doFinal(messageArray);
            //metto il messaggio criptato in un ramo del value e inizializzo il ramo chiave privata a cui assegnerò il valore succesivamente
            ByteArray encryptedMessage = new ByteArray(encryptedMessageArray);
            valueEncryption.getFirstChild("messaggio_criptato").setValue(encryptedMessage);
            byte[] emptyArray = null;
            ByteArray empty = new ByteArray(emptyArray);
            valueEncryption.getFirstChild("chiave_privata").setValue(empty);
        } catch (Exception e) {
            e.printStackTrace();
        }
        //restituisco il value con il messaggio codificato
        return valueEncryption;
    }


        //metodo che decifra un messaggio criptato con una chiave privata
    public static Value decryption(Value inputValue){
        //prendo dal value in input la chiave privata e il messaggio da decriptare
        ByteArray privateKey = inputValue.getFirstChild("chiave_privata").byteArrayValue();
        byte[] privateKeyArray = privateKey.getBytes();
        ByteArray encryptedMessage = inputValue.getFirstChild("messaggio_criptato").byteArrayValue();
        byte[] encryptedMessageArray  = encryptedMessage.getBytes();
        //inizializzo il value da dare in output
        Value valueDecryption = Value.create();
        try{
            //creo un oggetto PrivateKey con l'array di byte della chiave privata ricevuta in input
            KeyFactory keyFactor = KeyFactory.getInstance("RSA");
            PrivateKey prvKey = keyFactor.generatePrivate(new PKCS8EncodedKeySpec(privateKeyArray));
            //decodifico il messaggio criptato
            Cipher cipher = Cipher.getInstance("RSA");
            cipher.init(Cipher.DECRYPT_MODE, prvKey);
            byte[] messageArray = cipher.doFinal(encryptedMessageArray);
            //trasformo il messaggio decodificato in una stringa e lo metto nel value
            String message = new String(messageArray, "UTF8");
            valueDecryption.getFirstChild("messaggio").setValue(message);
        }catch (Exception e){
            e.printStackTrace();
        }
        //restituisco il value con il messaggio
        return valueDecryption;
    }


    //metodo che prende una stringa hash la codifica generando così una firma digitale
    public static Value digitalSignature(Value inputValue){
        //estraggo dall'input la chiave privata e la stringa hash
        ByteArray privateKey = inputValue.getFirstChild("chiave_privata").byteArrayValue();
        byte[] privateKeyArray = privateKey.getBytes();
        String hashMessage = inputValue.getFirstChild("messaggio_hash").strValue();
        byte[] hashMessageArray = hashMessage.getBytes();
        //creo un value per l'output
        Value valueDigitalSignature = Value.create();
        try{
            //assegno ad un oggetto PrivateKey la chiave privata presa dell'input
            KeyFactory keyFactor = KeyFactory.getInstance("RSA");
            PrivateKey prvKey = keyFactor.generatePrivate(new PKCS8EncodedKeySpec(privateKeyArray));
            //codifico il messaggio hash e ottengo la firma digitale
            Cipher cipher = Cipher.getInstance("RSA");
            cipher.init(Cipher.ENCRYPT_MODE, prvKey);
            byte[] digitalSignature = cipher.doFinal(hashMessageArray);
            //aggiungo la firma digitale al value e inizializzo altri due rami vuoti
            ByteArray digitalSignatureArray = new ByteArray(digitalSignature);
            valueDigitalSignature.getFirstChild("firma_digitale").setValue(digitalSignatureArray);
            byte[] emptyArray = null;
            ByteArray empty = new ByteArray(emptyArray);
            valueDigitalSignature.getFirstChild("chiave_pubblica").setValue(empty);
            String emp = "";
            valueDigitalSignature.getFirstChild("messaggio_hash").setValue(emp);
        }catch (Exception e){
            e.printStackTrace();
        }
        //restituisco il value con la firma digitale
        return valueDigitalSignature;
    }


    //metodo per controllare che il messaggio ricevuto nella chat pubblica sia integro e che l'identità del mittente sia garantita
    public static Value compare(Value inputValue){
        //prendo la chiave pubblica, la firma digitale e il messaggio ricevuto in chat, trasformato in hash, dal value in input
        ByteArray publicKey = inputValue.getFirstChild("chiave_pubblica").byteArrayValue();
        byte[] publicKeyArray = publicKey.getBytes();
        ByteArray digitalSignature = inputValue.getFirstChild("firma_digitale").byteArrayValue();
        byte[] digitalSignatureArray = digitalSignature.getBytes();
        String hashMessageInput = inputValue.getFirstChild("messaggio_hash").strValue();
        //inizializzo il value per l'output
        Value valueCompare = Value.create();
        try{
          //assegno ad un oggetto PublicKey la chiave pubblica presa in input
          KeyFactory keyFactor = KeyFactory.getInstance("RSA");
          PublicKey pubKey = keyFactor.generatePublic(new X509EncodedKeySpec(publicKeyArray));
          //decripto la firma digitale ottenendo il messaggio hash
          Cipher cipher = Cipher.getInstance("RSA");
          cipher.init(Cipher.DECRYPT_MODE, pubKey);
          byte[] hashMessageArray = cipher.doFinal(digitalSignatureArray);
          //trasformo in stringa il messaggio hash
          String hashMessage = new String(hashMessageArray, "UTF8");
          //confronto che la stringa hash preso in input sia uguale alla stringa hash ottenuta prima
          boolean right = false;
          if(hashMessageInput.equals(hashMessage)){
              right = true;
          } else {
              right = false;
          }
          valueCompare.getFirstChild("corretto").setValue(right);
        }catch (Exception e){
            e.printStackTrace();
        }
        //restituisco il valore boolean attraverso il value
        return valueCompare;
    }



}
