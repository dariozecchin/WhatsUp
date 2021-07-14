include "console.iol"
include "Interfaccia.iol"
include "ui/swing_ui.iol"
include "string_utils.iol"
include "Runtime.iol"


inputPort Porta_Open {
Location: "socket://localhost:8001"
Protocol: http
Interfaces: Int
}

outputPort Porta_Peer {
Protocol: http
Interfaces: Int
}

outputPort Monitor_Output {
Location: "socket://localhost:9100"
Protocol: http
Interfaces: Int
}

inputPort Porta_Server_Input {
Location: "socket://localhost:9300"
Protocol: http
Interfaces: Int
}



init{

  global.counter = 0
  global.array = 0

}



execution{ concurrent }

main{
  //metodo che aggiunge il peer al network
  [joinNetwork(account)(result){
    ok = true
    //ciclo che controlla che nel network non ci sia nessun peer con quello username
    for(i=0, i<#global.array.username,i++) {
      if(account.username==global.array.username[i]) {
      ok = false
      }
    }
    //se non c'è, il peer viene registrato al network
    if(ok){
      result = true
      global.array.username[global.counter] = account.username;
      global.array.porta[global.counter] = account.porta;
      global.counter++
      //se è già presente la registrazione viene interrotta
    } else {
      result = false
      Porta_Peer.location = account.porta;
      monitorMessage = "L'username " + account.username + " è già registrato alla rete pertanto la registrazione verrà interrotta";
      messaggiMonitor@Monitor_Output(monitorMessage)
      //il peer viene terminato
      killPeer@Porta_Peer()
    }
  }]


  //stampa l'elenco dei peer registrati nella rete
  [stampoArray(portNumber)]{
    counter = 0;
    Porta_Peer.location = portNumber;
    //trovo in quale posizione è il peer che ha fatto richiesta della lista
    for(j = 0, j < #global.array.username, j++){
      if(global.array.porta[j] == portNumber){
        counter = j
      }
    }
    //scorro tutti i peer della lista
    for(i = 0, i < #global.array.username, i++){
      indexUsername = global.array.username[i];
      indexPortNumber = global.array.porta[i];
      //se il peer non è quello che ha fatto richiesta lo stampo sul terminale del peer
      if(i != counter){
        peerOnlineString = "NOME = " + indexUsername + " - " + "PORTA = " + indexPortNumber;
        //println@Console( "Nome " + count + " porta " + count1 )()
        stampaSuWeer@Porta_Peer(peerOnlineString)
      }
    }
  }


  //verifico che il peer che vuole iniziare una chat non sia l'unico nella rete
  [controlloPrimoElemento()(check){
    size = #global.array.username;
    //se l'array ha un solo elemento il peer non può iniziare una comunicazione
    if(size == 1){
      check = true //torna la menu
    } else {
      check = false
    }
  }]

  //metodo che fa stare non fa avviare una chat di gruppo finchè non ci sono almeno 2 Peer online
  [controlloChatDiGruppo()(check){
    size = #global.array.username;
    //minimo 3 account
    if(size < 3){
      check = true //torna al menu
    } else {
      check = false
    }
  }]


  //metodo che permette ad un peer di lasciare il network
  [leaveNetwork(portNumber)]{
    //scorro l'array globale dove sono segnati tutti i peer registrati alla rete
    for(i = 0, i < #global.array.username, i++){
      indexPortNumber = string(global.array.porta[i])
      //trovo la porta del peer che vuole lasciare la rete
      if(indexPortNumber == portNumber){
        //elimino dall'array il peer
        undef(global.array.porta[i]);
        undef(global.array.username[i]);
        //decremento il counter in modo da aggiungere il prossimo peer nella posizione lasciata libera da questo peer
        global.counter--
      }
    }
  }
}
