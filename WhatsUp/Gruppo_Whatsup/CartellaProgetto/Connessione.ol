include "console.iol"
include "interfaccia.iol"
include "ui/swing_ui.iol"
include "Runtime.iol"


inputPort Porta_input {
Location:"local"
Protocol: http
Interfaces: Int
}

outputPort Weer {
Protocol: http
Interfaces: Int
}

outputPort Porta_Server_OutputP {
Location: "socket://localhost:9300"
Protocol: http
Interfaces: Int
}

outputPort Monitor_Output {
Location: "socket://localhost:9100"
Protocol: http
Interfaces: Int
}

cset {
  sessionToken: InRequest.token

}
cset {
  chatToken : Chat.token

}

define menu {
  println@Console("////////////////////////////////////////////")();
  println@Console("NON CHIUDERE LA SWING")()
  println@Console("////////////////////////////////////////////")();

  println@Console("0) Accetta la connessione se richiesto ")()
  println@Console("1) Chat privata")()
  println@Console("2) Chat di gruppo")()
  println@Console("3) Lascia la rete ")()
  showInputDialog@SwingUI( "Inserisci il numero dell'azione che vuoi fare "+portaWeerarrivata )( sceltaAzione )
  testo = int(sceltaAzione)


  // nel caso venga accettata la connessione
  if(testo == 0){
    println@Console("...")()
    undef(tokenPeerRichiedente)
    Weer.location = portaWeerarrivata;
    scope (richiestaConnessione) {
      install( default =>
    getTokenConn@Weer()(tokenPeerQuesto);// prende da se stesso il token
    getEmbTokenConnessione@Weer()(tokenPeerRichiedente)// prende il token dal weer richiedente
      )
    }
    if( tokenPeerRichiedente == tokenPeerQuesto){
      inviaRisposta@Weer(2);
      // in caso il token fosse valido
      println@Console("Connessione stabilita, aspetta ancora qualche secondo..")()
    } else {
        println@Console("L'altro Weer ha abbandonato la chat")()
        menu
    }
  } else {
    //questa istruzione indica che questo peer è occupato
    Weer.location = portaWeer;
    inviaRisposta@Weer(1)
  };
  // segna che il weer non ha accetato la connessione
  if(testo == 1){
    strO = "Il Peer situato nella porta " + WRITER_LOCATION + " ha digitato l'opzione numero 1 del menù e vuole avviare una chat PRIVATA";
    messaggiMonitor@Monitor_Output(strO);
    controlloPrimoElemento@Porta_Server_OutputP()(boolLL)
    elemBL = bool(boolLL)
    if(elemBL){
      strM = "Il Peer " + WRITER_LOCATION + " non può inziare una chat privata poichè se il primo Peer che si registra attendi che vengano altri account ";
      messaggiMonitor@Monitor_Output(strM)
      menu
    } else {
      println@Console("LISTA UTENTI REGISTRATI NELLA RETE")();
      stampoArray@Porta_Server_OutputP(WRITER_LOCATION);
      showInputDialog@SwingUI( "Inserisci il numero della porta con cui vuoi comunicare tra la lista dei registrati " )( sceltaAzione );
      varPorta = "socket://localhost:" + sceltaAzione
      Weer.location = varPorta;
      println@Console("Rimani in attesa per qualche secondo ....")()
      scope( eccezioneGetOccupato2 ) {
        install( faultGetOccupato2 => println@Console( "Errore nel servizio getOccupato" )() );
        getOccupato@Weer()(risp)// nel caso non fosse occupato l'altro weer
      };
      if(!risp){
        token   = new;
        messaggiorichiesta.myporta = portaWeerarrivata;
        messaggiorichiesta.token = token ;
        Weer.location = portaWeerarrivata;
        scope( eccezioneSetTokenConn ) {
          install( faultSetTokenConn => println@Console( "Errore con il servizio setTokenConn" )() )
            setTokenConn@Weer(token)// set token a se stesso
        }
        Weer.location = varPorta;
        scope( eccezionemandaMessaggio1 )  {
          install( faultmandaMessaggio1 => println@Console( "Errore con il servizio mandaMessaggio" )() );
            mandaMessaggio@Weer(messaggiorichiesta)(accetta)
        }
        /* l'ultimo servizio controlla se il weer ha premuto 0 per accettare,
        e se il token di questo è ancora valido */
        } else {
          menu
        }
        if(accetta){
          Weer.location = portaWeerarrivata;
          strZM = "Il Peer situato nella porta " + varPorta + " ha accettato la connessione quindi la richiesta di chat PRIVATA/PUBBLICA";
          messaggiMonitor@Monitor_Output(strZM)
          scope( eccezioneAttesa ) {
            install( faultAttesa => println@Console( "Errore nel servizio attesa" )() );
              //attesa fa avviare la chat
              attesa@Weer(varPorta)          }

        } else {
          println@Console("L'altro Weer non vuole parlarti")();
          strZM2 = "Il Peer situato nella porta " + varPorta + " NON ha accettato la connessione quindi la richiesta di chat PRIVATA/PUBBLICA";
          messaggiMonitor@Monitor_Output(strZM2);
          Weer.location = portaWeerarrivata;
          scope( eccezioneSetTokenConn1 ) {
            install( faultSetTokenConn1 => println@Console( "Errore con il servizio setTokenConn1" )() )
            setTokenConn@Weer(" ")
          }
          Weer.location = varPorta;
          weerScaduto@Weer(portaWeerarrivata);
          menu
      }
    }
  }

  //scelta n°2
  if(testo == 2){
    //metodo chat di gruppo
    str1 = "Il Peer situato nella porta " + WRITER_LOCATION + " ha digitato l'opzione numero 2 del menù e vuole avviare una chat PUBBLICA";
    messaggiMonitor@Monitor_Output(str1);
    //controllo che fino a quando non ci sono almeno 3 Peer la Chat di gruppo non si può avviare
    controlloChatDiGruppo@Porta_Server_OutputP()(variabileLL);
    elementoBoolLL = bool(variabileLL);
    if(elementoBoolLL){
      strLL = "Il Peer " + WRITER_LOCATION + " non può inziare una chat PUBBLICA poichè non ci basta Peer collegati sulla rete ";
      messaggiMonitor@Monitor_Output(strLL);
      menu
    } else {
      println@Console("LISTA UTENTI REGISTRATI NELLA RETE")();
      stampoArray@Porta_Server_OutputP(WRITER_LOCATION);
      // questo indice il numero di weer che sono liberi
      j = 0 ;
      undef( global.weerPassati );
      undef(global.chatDiGruppo);
      //Viene chiesto il nome della chat...
      showInputDialog@SwingUI( "Inserisci il nome della chat" )( nomeGruppo )
      global.chatDiGruppo.nome = nomeGruppo;
      showInputDialog@SwingUI( "Inserisci il numero di partecipanti " )( numeroWeerGruppo )
      for ( i = 0 , i < numeroWeerGruppo, i ++){
          showInputDialog@SwingUI( "Inserisci il numero di porta del Weer #"+i )( portaWeerGruppo )
          varPorta = "socket://localhost:"+portaWeerGruppo
          Weer.location = varPorta;
          scope( eccezioneGetOccupato1 ) {
            install( faultGetOccupato1 => println@Console( "Errore nel servizio getOccupato" )() );
            getOccupato@Weer()(risposta)
          };

          if(!risposta){
            global.chatDiGruppo[j].porta= varPorta;
            j++
          }
      }
      // se i peer sono 1( bisogna contare anche questo peer che inizia la comunicazione) ,
      //Non viene fatta partire neanche la chat di  gruppo
      if(j <= 1 ) {
        println@Console( "ERRORE!!! Gli altri peer sono occupati  ")()
      } else {
        println@Console("Gli altri peer sono liberi per comunicare, vediamo se vogliono iniziare una chat di gruppo")()
        accountCheHannoAccettato=0 ;
        token   = new;
        messaggiorichiesta.myporta = portaWeerarrivata;
        messaggiorichiesta.token = token ;
        Weer.location = portaWeerarrivata;
        scope( eccezioneSetTokenConn2 ) {
          install( faultSetTokenConn2 => println@Console( "Errore con il servizio setTokenConn2" )() )
          setTokenConn@Weer(token)
        }
        for ( i = 0 , i < j, i ++){
          Weer.location = global.chatDiGruppo[i].porta;
          undef ( accetta);
          scope( eccezionemandaMessaggio2 )  {
            install( faultmandaMessaggio2 => println@Console( "Errore con il servizio mandaMessaggio" )() );
              mandaMessaggio@Weer(messaggiorichiesta)(accetta)
          }
          if(accetta){
            strZ = "Il Peer situato nella porta " + global.chatDiGruppo[i].porta + " ha accettato la connessione quindi la richiesta di chat PRIVATA/PUBBLICA";
            messaggiMonitor@Monitor_Output(strZ);
            Weer.location = portaWeerarrivata;
            global.weerPassati.account[accountCheHannoAccettato].porta=  global.chatDiGruppo[i].porta;
            //attesa fa avviare la chat
            accountCheHannoAccettato++
          } else {
            strZMZ = "Il Peer situato nella porta " + global.chatDiGruppo[i].porta + " NON ha accettato la connessione quindi la richiesta di chat PRIVATA/PUBBLICA";
            messaggiMonitor@Monitor_Output(strZMZ);
            Weer.location = portaWeerarrivata;
            scope( eccezioneSetTokenConn3 ) {
              install( faultSetTokenConn3 => println@Console( "Errore con il servizio setTokenConn3" )() )
              setTokenConn@Weer(" ")// sessione scaduta assegna token vuoto
            };

            Weer.location = global.chatDiGruppo[i].porta;
            weerScaduto@Weer(portaWeerarrivata)
          }
        }
        if(accountCheHannoAccettato >= 2  ) {
          if(accountCheHannoAccettato== j ) {
            println@Console("Tutti i peer hanno accettato la connessione ")()
          } else {
          println@Console("!!!!! NON Tutti i peer hanno accettato la connessione ")()
          println@Console("Pero' comunque si puo' inziare una chat ;)  ")()
          }
          global.weerPassati.chatName = nomeGruppo;
          Weer.location = portaWeerarrivata;
          scope( eccezioneAttesaDiGruppo ) {
            install( faultAttesaDiGruppo => println@Console( "Errore nel servizio attesaDiGruppo" )() );
            attesaDiGruppo@Weer(global.weerPassati)
          }
        } else {
          println@Console( "ERRORE!!! Il numero di Weer minimo minimo non e' stato raggiunto  ")();
          if(is_defined(global.weerPassati )){
            println@Console("La porta del weer passato e' "+  global.weerPassati.account[0].porta)()
            Weer.location =   global.weerPassati.account[0].porta;
            weerInsuf@Weer(portaWeerarrivata)
          }
          menu
        }
      }
    }
  }

  //
  if(testo == 3){
    str2 = "Il Peer situato nella porta " + WRITER_LOCATION + " ha digitato l'opzione numero 3 del menù e HA LASCIATO definitivamente la rete";
    messaggiMonitor@Monitor_Output(str2)
    leaveNetwork@Porta_Server_OutputP(WRITER_LOCATION);
    halt@Runtime()()
  }

}


main {

  //esegui richiama il metodo in cui viene passata la porta del proprio Weer
  [esegui(portaWeerarrivata)]{
    portaWeer = portaWeerarrivata;
    menu
  }

}
