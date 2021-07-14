include "console.iol"
include "Interfaccia.iol"
include "ui/swing_ui.iol"
include "string_utils.iol"
include "file.iol"
include "semaphore_utils.iol"
include "Time.iol"
include "Runtime.iol"
include "Converter.iol"
include "message_digest.iol"


outputPort Porta_Server {
Location: "socket://localhost:8001"
Protocol: http
Interfaces: Int
}

inputPort Porta_input {
Location: WRITER_LOCATION
Protocol: http
Interfaces: Int
}

outputPort Porta_output {
Protocol: http
Interfaces: Int
}

outputPort embMenu {
Protocol: http
Interfaces: Int
}

outputPort Monitor_Output {
Location: "socket://localhost:9100"
Protocol: http
Interfaces: Int
}

outputPort Porta_Crittografia {
    Interfaces: Crittografia
}


embedded {
    Java: "example.Crittografia" in Porta_Crittografia
}


define __embSend {
/*In questo metodo viene richiamato il file Connessione.ol
tramite in embeeding.
Questo file contiene il Menù dell'applicazione e gestisce la Connessione
tra i vari weer */
  with( emb ) {
    .filepath ="Connessione.ol";
    .type = "Jolie"
  };
  loadEmbeddedService@Runtime( emb )( embMenu.location);
  esegui@embMenu(global.account.porta)
}

define chat1 {
  //metodo che viene richiamato nella Chat Privata dopo
  //aver controllato i diversi token per instaurare una connessione
  richiesta.user = global.account.username
  richiesta.porta = global.account.porta
  richiesta.token = "  "
  Porta_output.location = global.accountChat.porta;
  scope( eccezioneChat1 ) {
    install( faultChat1 => println@Console( "Errore con il servizio chat" )() )
    chat@Porta_output(richiesta)
  }
}

define chat2 {
  //metodo che viene richiamato nella Chat di gruppo dopo
  //aver controllato i diversi token per instaurare una connessione
  token   = new;
  richiesta.portaPeer = global.account.porta;
  richiesta.token = token
  richiesta.nomeChat = global.chatName
  //viene passato su richiesta l'albero degli account che compongono il gruppo
  richiesta << global.chatGruppo
  //per ogni account viene avviato il metodo
  for( i = 0 ,i <  #global.chatGruppo.account, i++) {
    Porta_output.location = global.chatGruppo.account[i].porta
    scope( eccezioneChatdiGruppo1 ) {
      install( faultChatdiGruppo1 => println@Console( "Errore con il servizio chatDiGruppo" )() )
      chatDiGruppo@Porta_output(richiesta)
    }
    //metodo chat a ogni peer
  }
  //infine anche al Weer stesso
  Porta_output.location = WRITER_LOCATION;
  scope( eccezioneChatdiGruppo2 ) {
    install( faultChatdiGruppo2 => println@Console( "Errore con il servizio chatDiGruppo" )() )
    chatDiGruppo@Porta_output(richiesta)
  }
}


//Per gestire i token della chat e i token della scrittura da termiale
cset {
  chatToken : Chat.token
}

cset {
  sessionToken: InRequest.token
}


init{
  // questa variabile tiene traccia se un weer è occupato in una comunicazione o meno
  global.occupato = false;
  //username
  global.account.username = args[0];
  //porta
  global.account.porta = WRITER_LOCATION;
  //questa variabile ha tre valori, ed è la "compagna" di occupato ,
  //inizializzata a 0 e può essere settata a 1 e a 2
  //che indica comunque che il peer è occupato
  //quando gli viene inoltrata una richiesta ,
  //viene atteso un lasso di tempo
  // se entro quel lasso di tempo non cambia
  //il valore di questa variabile ( ==  2 ) vuol dire che il peer non ha accetto la connessione
  global.attesaRispostaChat=0;
  // anche questa variabile registra se un peer è impegnato a instaurare una nuova connessione
  global.occupatoConnessione = false;
  // questa variabile contiene il token della chat
  // se entro un lasso di tempo la connessione "scade" questo
  //token viene settato a vuoto
  global.newChat.token = "  ";
  keyGenerator@Porta_Crittografia()(chiaviCoppia);
  chiavePubRaw = chiaviCoppia.chiave_pubblica;
  rawToBase64@Converter(chiavePubRaw)(global.public_key)
  global.private_key = chiaviCoppia.chiave_privata;
  registerForInput@Console( { enableSessionListener = true })();
  //quando un Weer viene avviato viene inserito nella lista centralizzata dei weer presenti
  scope( eccezioneJoinNetwork ) {
    install( faultJoin => println@Console( "Impossibile aggiungere Peer" )() );
      joinNetwork@Porta_Server(global.account)(res)
  }
  if(res == true){
    strConca = "Il Peer " + global.account.username + " si è unito con successo alla rete presso l'indirizzo " + global.account.porta;
    //lancio monitor
    messaggiMonitor@Monitor_Output(strConca)
    // dichiarazione del semaforo per gestire la scrittura su file
    // utilizzato anche il costrutto synchronized
    s.name = "semaforo s";
	  s.permits = 1
    //viene avviato il menù dopo che un weer si è registato
    __embSend
    }

}

execution{ concurrent }

main{

  [chat(datiRichiedente)]{
    global.occupato = true;
    //qui avviene la verifica che il metodo sia partito anche nell'altro Weer
    if ( datiRichiedente.token ==  "  "){
      global.chat.token = token   = new;
      datiRichiedente.token = token;
      request.user = global.account.username
      request.porta = global.account.porta
      request.token = token
      Porta_output.location = datiRichiedente.porta;
      scope( eccezioneChat ) {
        install( faultChat => println@Console( "Errore nel servizio chat" )() );
        chat@Porta_output(request)
      }
    }

    Porta_output.location = datiRichiedente.porta;
    //variabile che contiene lo stato dell'altro Weer
    occupatoAltroPeer=true;
    scope(DimensioneFile) {
      install( default =>
        println@Console("ERRORE Impossibile recuperare chiave pubblica")()
      );
      getchiavePubblica@Porta_output()(chiaveSuaPubbli)
    }
    base64ToRaw@Converter(chiaveSuaPubbli)(chiaveSuaPubblica)
    println@Console("I Weer sono pronti per la comunicazione \n Ora puoi scrivere.. ")()
    println@Console(" Scrivi exit se vuoi uscire dalla chat e tornale al menu ")()
    //monitor
    strGH = "Il Peer " + datiRichiedente.porta + " ha iniziato una chat con il Peer " + WRITER_LOCATION;
    messaggiMonitor@Monitor_Output(strGH)
    while( testo != "exit" && occupatoAltroPeer){
      global.chat.token = datiRichiedente.token
      //il nome del file di testo viene formato concatendo i due username
      scrittura.filename= datiRichiedente.user + global.account.username;
      global.chat.token.filename = scrittura.filename
      //token per l'input da tastiera
      token2 = new
      csets.sessionToken = token2
      subscribeSessionListener@Console( { token = token2 } )();
      synchronized( inputSession ) {
        in( testo )
      }
      unsubscribeSessionListener@Console( { token = token2 } )();
      messaggio ="\n"+global.account.username+":"+testo;
      //testoFile.testo = messaggio;
      vlEnc.messaggio = messaggio;
      vlEnc.chiave_pubblica = chiaveSuaPubblica;
      encryption@Porta_Crittografia(vlEnc)(ress);
      rawToBase64@Converter(ress.messaggio_criptato)( testoFile.testo)
      //testoFile.testo = ress.messaggio_criptato;
      with( scrittura ) {
       .content =messaggio;
       .append = 1
      }
      //questo if verifica che nel caso l'altro weer
      //esca dalla chat il valore viene cambiato
      if ( global.occupato == true){
        if(testo != "exit"  ){
          // condizione di uscita
          release@SemaphoreUtils(s)(tResponse);
          synchronized( syncToken ) {
            writeFile@File( scrittura )();
            //invia il messaggio all'altro Weer
            scope( eccezioneScriviSulFile ) {
              install( faultScriviSulFile => println@Console( "Errore con il servizio scriviSulFile" )() )
              scriviSulFile@Porta_output(testoFile)
            }
          };
          acquire@SemaphoreUtils(s)(sResponse)
        } else {
          strExit = "La chat PRIVATA tra il Peer " + datiRichiedente.porta + " e il Peer " + WRITER_LOCATION + " è TERMINATA";
          messaggiMonitor@Monitor_Output(strExit)
          // nel caso un Weer prema "exit" l'altro weer viene avvisato con un messaggio video
          getMessaggioAltroPeer@Porta_output()
        }
        scope( eccezioneGetOccupato ) {
          install( faultGetOccupato => println@Console( "Errore nel servizio getOccupato" )() );
          //questo metodo verifica che l'altro peer non sia uscito
          getOccupato@Porta_output()(occupatoAltroPeer)
        }

      } else{
        occupatoAltroPeer = false
      }
    }
    println@Console("Uscita dalla chat...")();
    global.occupato = false;
    global.attesaRispostaChat = 0 ;
    global.accountChat.porta = "";
    // tutte la variabili vengono inizializzate al valore iniziale
    __embSend
  }


  [scriviSulFile(request)]{
    //metodo sul weer che riceve il messaggio per stampare a video e
    //nel file della chat
    if (global.occupato){
      scrittura.filename = global.chat.token.filename;
      ress.chiave_privata = global.private_key;
      base64ToRaw@Converter(request.testo)(ress.messaggio_criptato);
      decryption@Porta_Crittografia(ress)(messaggio_finale);
      with( scrittura ) {
      .content = messaggio_finale.messaggio;
      .append = 1
      }
      // più un controllo sul token dell'altro peer
      release@SemaphoreUtils(s)(tResponse);
      synchronized( syncToken2 ) {
        println@Console( messaggio_finale.messaggio)();
         writeFile@File( scrittura )()
      }
      acquire@SemaphoreUtils(s)(sResponse)
    }
  }


  [chatDiGruppo(richiestaChat)]{
    global.occupato = true
    //Per ogni Weer viene aggiornato la lista in modo tale di non avere la propria porta
    for ( i = 0 , i < #richiestaChat.account, i++){
      if( global.account.porta !=richiestaChat.account[i].porta ) {
        global.chatGruppo.account[i].porta = richiestaChat.account[i].porta
      } else {
        global.chatGruppo.account[i].porta = richiestaChat.portaPeer
      }
    }
    // Il nome della chat viene concatenato con il nome del weer
    // in modo che il file txt sia più facile trovare e per evitare
    //confilitti in caso venga eseguita in locale
    global.chatName = richiestaChat.nomeChat + global.account.username
    occupatoChatPeer=true;
    println@Console("I Weer sono pronti per comunicare \n Ora puoi scrivere.. ")();
    println@Console(" Scrivi exit se vuoi uscire dalla chat e tornale al menu ")()
    while( testo != "exit" && occupatoChatPeer){
      scrittura.filename= global.chatName;
      token2 = new
      csets.sessionToken = token2
      subscribeSessionListener@Console( { token = token2 } )();
      synchronized( inputSession ) {
        in( testo )
      }
      unsubscribeSessionListener@Console( { token = token2 } )();
      messaggio ="\n"+global.account.username+":"+testo;
      md5@MessageDigest(messaggio)(ris);
      strRis = string(ris);
      dd.messaggio_hash = strRis;
      dd.chiave_privata = global.private_key;
      digitalSignature@Porta_Crittografia(dd)(inout);
      testoFile.testo = messaggio
      rawToBase64@Converter(inout.firma_digitale)(inout.firma_digitale);
      testoFile.firmaDigitale =inout.firma_digitale
      with( scrittura ) {
        .content =messaggio;
        .append = 1
      }
      if ( global.occupato == true){
        if(testo != "exit"  ){
          release@SemaphoreUtils(s)(tResponse);
          synchronized( syncToken ) {
            writeFile@File( scrittura )();
            for ( i = 0 , i < #global.chatGruppo.account, i++){
              if(global.chatGruppo.account[i].porta != " "){
                Porta_output.location = global.chatGruppo.account[i].porta;
                testoFile.location = global.account.porta
                scope( eccezioneScriviSulFile2 ) {
                  install( faultScriviSulFile2 => println@Console( "Errore con il servizio scriviSulFile2" )() )
                  scriviSulFile2@Porta_output(testoFile)
                }
              }
            }
          };
          acquire@SemaphoreUtils(s)(sResponse)
        } else {
          for ( i = 0 , i < #global.chatGruppo.account, i++)
            if(global.chatGruppo.account[i].porta != " "){
              Porta_output.location  = global.chatGruppo.account[i].porta;
              avvisaAltriWeer@Porta_output(global.account.porta)
            }
        }
      } else {
        occupatoChatPeer = false
      }
    }
    println@Console("Sto abbandonando la chat ...")();
    global.occupato = false;
    global.attesaRispostaChat = 0 ;
    undef(global.chatGruppo)
    __embSend
  }

  //versione del metodo sopra però per la chatDiGruppo
  [scriviSulFile2(request)]{
    if (global.occupato){
      scope(DimensioneFile) {
        install( default =>
          println@Console("ERRORE")()
        );
        Porta_output.location = request.location
        getchiavePubblica@Porta_output()(chiaveSuaPubbli)
      }
      base64ToRaw@Converter(chiaveSuaPubbli)(inout.chiave_pubblica)
      md5@MessageDigest(request.testo)(inout.messaggio_hash);
      base64ToRaw@Converter(request.firmaDigitale)(inout.firma_digitale)
      compare@Porta_Crittografia(inout)(tutto_corretto);
      if( tutto_corretto.boolean ==false ) {
        leaveNetwork(WRITER_LOCATION)
      }
      scrittura.filename = global.chatName;
      with( scrittura ) {
        .content =request.testo;
        .append = 1
      }
      release@SemaphoreUtils(s)(tResponse);
      synchronized( syncToken2 ) {
        println@Console(request.testo)();
        writeFile@File( scrittura )()
      };
      acquire@SemaphoreUtils(s)(sResponse)
    }
  }


  [avvisaAltriWeer(portaUscente)]{
    // avvisa ogni Weer nella chat di Gruppo che il Weer corrente sta uscendo
    for ( i = 0 , i < #global.chatGruppo.account, i++){
      if( global.chatGruppo.account[i].porta == portaUscente){
        global.chatGruppo.account[i].porta = " "
        println@Console("Il weer "+ portaUscente + " e' uscito dalla chat ")()
      }
    }
  }


  [getOccupato()(response){
    response = global.occupato
  }]

  [getMessaggioAltroPeer()]{
    global.occupato = false;
    println@Console("L'altro weer e' uscito dalla conversazione \n PREMI INVIO PER CONTINUARE")()
  }

  //questo servizio gestisce la connessione dei Weer
  [mandaMessaggio(portaWeerRichiedente)(response){
    global.attesaRispostaChat = 0;
    // questo blocca tutte le connessione entranti quando il menu
    // è in attesa di una risposta a un altro weer
    if( global.occupatoConnessione == false){
      global.accountChat.porta = portaWeerRichiedente.myporta;
      global.occupatoConnessione = true;
      global.newChat.token = portaWeerRichiedente.token;
      Porta_output.location = portaWeerRichiedente.myporta
      // nel caso si prema 0
      println@Console("Premi 0 nel TERMINALE SWING per accettare la connessione DAL WEER " + portaWeerRichiedente.myporta)();
      // attesa che viene data per accettare la Connessione
      // passato questo lasso di tempo la sessione sara' scaduta
      sleep@Time(10000)();
      if(global.attesaRispostaChat==0 || global.attesaRispostaChat==1){
        // nel caso nel terminale non si prema 0 per accettare questa Connessione
        // vorrà dire che la richiesta è stata rifiutata
        response = false
      } else {
        response = true
      }
    } else {
      response = false
    }
    global.occupatoConnessione = false
  }]

  [attesa(request)]{
    global.accountChat.porta = request;
    chat1 // avvia la chat
  }


  [attesaDiGruppo(request)]{
    global.chatName = request.chatName;
    for( i = 0 , i < #request.account , i ++){
      global.chatGruppo.account[i].porta = request.account[i].porta
    }
    chat2 // avvia la chat di gruppo
  }


  [inviaRisposta(request)]{
    global.attesaRispostaChat = request
  }


  [menu()]{
    __embSend
  }


  [setTokenConn(request)]{
    global.newChat.token = request
  }


  [getTokenConn()(response){
    response = global.newChat.token
  }]


  [getEmbTokenConnessione()(token){
    Porta_output.location = global.accountChat.porta;
    scope( eccezionegetTokenConn )  {
      install( faultgetTokenConn => println@Console( "Errore nel servizio getTokenConn" )() );
        getTokenConn@Porta_output()(token)
    }

  }]


  [weerScaduto(portaWeerRichiedente)]{
    println@Console("\n")();
    println@Console("////////////////////////////////////////////////////////////////////////////////////////")();
    println@Console("Il weer "+portaWeerRichiedente+" ha tentanto di iniziare una comunicazione senza successo")();
    println@Console("////////////////////////////////////////////////////////////////////////////////////////")()
  }


  [killPeer(res)]{
    halt@Runtime()()
  }


  [weerInsuf(portaWeerRichiedente)]{
    println@Console("\n")();
    println@Console("////////////////////////////////////////////////////////////////////////////////////////")();
    println@Console("Il weer "+portaWeerRichiedente+" ha tentanto di iniziare una chatDiGruppo senza successo")();
    println@Console("////////////////////////////////////////////////////////////////////////////////////////")()
    __embSend
  }



  //stampa solo la stringa data
  [stampaSuWeer(strDaStampare)]{
    println@Console(strDaStampare)()
  }

  [getchiavePubblica()(chiaveMiaPubblica){
    chiaveMiaPubblica =global.public_key
  }]
}
