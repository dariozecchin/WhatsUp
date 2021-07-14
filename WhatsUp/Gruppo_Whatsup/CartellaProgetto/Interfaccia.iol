//type utilizzati nel progetto
type Dati : void{
.user : string
.porta : string
.token: string
}

type DatiGruppo : void{
.nomeChat : string
.portaPeer: string
.token: string
.account* :void { // utilizzando l'asterisco permette di utilizzare una varibile composta da più elementi
  .porta : string
  }
}

type Gruppo: void {
  .chatName:string
  .account* :void {
    .porta : string
  }
}

type Chat : void {
  .token : string
}


type MessaggioTesto : void {
  .testo : string
}

type MessaggioTestoHash : void {
  .testo : string
  .firmaDigitale : string
  .location : string
}

type Account : void{ //type che indica gli elementi di un Peer
  .username : string //stringa che fa riferimento all'username
  .porta : string //stringa che fa riferimento alla porta
}

type MessToken : void {
  .token : string
  .myporta : string
}


//type della crittografia
type Chiavi : void{ //type che serve per restituire due chiavi nel servizio keyGenerator
  .chiave_pubblica: raw //ritorna una chiave_pubblica in ByteArray
  .chiave_privata: raw //ritorna una chiave_privata in ByteArray
}

type Cifratura : void{ //type che permette di prendere in input nel servizio encryption il messaggio da criptare e la sua relativa chiave pubblica
  .chiave_pubblica: raw //chiave_pubblica
  .messaggio: string //string riferito al messaggio da criptare
}

type Decifratura : void{ //type che permette di passare al servizio decryption il messaggio precedentemente criptato da string a raw e la sua chiave per decriptarlo
  .messaggio_criptato: raw //messaggio criptato in raw
  .chiave_privata: raw //chiave privata con cui decrifrare il messaggio
}

type Messaggio : void{ //type che indica il messaggio decriptato che esce da decryption
  messaggio: string
}

type FirmaDigitale : void{ //type che permette di avere una stringa in hash con relativa chiave privata
  messaggio_hash: string //messaggio hashato con md5
  chiave_privata: raw
}

type ControlloFD : void{ //type usato nel servizio compare per valutare l'integrità del messaggio
  .chiave_pubblica: raw //chiave pubblica con cui decifrare il messaggio
  .firma_digitale: raw //firma digitale ottenuta dal servizio digitalSignature
  .messaggio_hash: string //string riferito al messaggio su cui valutare l'integrità
}

type Boolean : void{ //type usato in compare per verificare l'integrità del messaggio
  .corretto: bool //se true il messaggio corrisponde con quello mandato dal mittente, viceversa se false
}


constants{
  WRITER_LOCATION = "socket://localhost:8009"
}

interface Int {

OneWay:
  chat(Dati), // servizio della chat
  scriviSulFile(MessaggioTesto),  // servizio per poter mandare il messaggio all'altro Weer
  scriviSulFile2(MessaggioTestoHash),
  chatDiGruppo(DatiGruppo),
  menu(void),
  getMessaggioAltroPeer(void),
  esegui(string), // servizio base per richiamare il menù su Connessione.ol
  setTokenConn(string), //  servizio che permette di impostare il token nel Weer richiedente
  attesa(string),  // servizio che precede il servizio chat
  attesaDiGruppo(Gruppo),
  inviaRisposta(int), // servizio per gestire la concorrenza di diverse richieste
  weerScaduto(string),  // comunica al Weer che il tentativo di connessione è scaduto
  stampoArray(string), //servizio per stampare i Peer che sono online.
  messaggiMonitor(string), //servizio che stampa sul monitor ciò che avviene nella rete.
  leaveNetwork(string), //servizio per lasciare la rete.
  killPeer(void), //servizio che serve per chiudere il terminale di un Peer nel caso in cui l'username inserito da un Peer fosse già presente nella rete.
  stampaSuWeer(string), //servizio lanciato in stampoArray che permette di vedere i nomi dei Peer online con cui poter avviare una comunicazione.
  weerInsuf(string), // servizio che comunica un tentativo di chatDiGruppo
  avvisaAltriWeer(string) // servizio che comunica ai Weer che un Weer è uscito dalla chat di gruppo

RequestResponse:
  joinNetwork(Account)(bool), //servizio che aggiunge un Peer sulla rete e torna un valore booleano, se il valore è true vuol dire che è stato aggiunto se il valore invece è false vuol dire che l'username del Peer è già presente nella rete dunque ritorna un valore false.
  mandaMessaggio(MessToken)(bool),  // servizio che controlla che il Weer abbia accettato la richiesta di connessione
  getOccupato(void)(bool),  // servizio che ritorna il valore della variabile occupato
  getTokenConn(void)(string), // servizio che ritorna il token del Weer1
  getEmbTokenConnessione(void)(string), // servizio che ritorna il token del Weer2
  controlloPrimoElemento(void)(bool), //controllo per far stare in attessa il primo Peer che si connette alla chat privata.
  getchiavePubblica(void)(string), // servizio che ritorna la chiave pubblica del Weer2
  controlloChatDiGruppo(void)(bool) //controllo per far stare in attessa i primi due Peer che si connettono alla chat Pubblica.

}

interface Crittografia {
RequestResponse:
  keyGenerator(void)(Chiavi),
  encryption(Cifratura)(Decifratura),
  decryption(Decifratura)(Messaggio),
  digitalSignature(FirmaDigitale)(ControlloFD),
  compare(ControlloFD)(Boolean)

}
