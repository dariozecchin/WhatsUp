include "console.iol"
include "Interfaccia.iol"

inputPort Monitor_Input {
Location: "socket://localhost:9100"
Protocol: http
Interfaces: Int
}

init{
  println@Console("Benvenuto nel monitor di Whatsup")();
  //definisco variabile count
  global.countMonitor = 0
}

execution{ concurrent }

main{
  [messaggiMonitor(str)]{
    synchronized( tokenMonitor ){
      //incremento il mio token
      global.countMonitor++;
      println@Console(global.countMonitor + " -> " + str)()
    }
  }
}
