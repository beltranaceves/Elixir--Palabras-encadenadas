# Palabras Encadenadas PWA
## [Live demo](https://as-p3-palabras-encadenadas.gigalixirapp.com/)
## Herramientas para testear
[HTTPoison](https://github.com/edgurgel/httpoison)


## Instrucciones
Como ejecutar el servidor en local:
```cmd
iex -S mix run --no-halt
```

Como mandar una query a la base de datos a través de IEX:
```elixir
query = "SELECT * FROM USERS;"
WordChain.Repository.query(query)
```

Como generar la documentación de la aplicación:
```cmd
mix docs
```


Para comprobar que el supervisor reinicia correctamente los procesos:
```elixir
pid = Process.whereis(WordChain.GameServer) #Nombre con el que esta registrado el pid de ese GenServer
Process.exit(pid, :kill) #Mata el proceso de forma no ordenada
Process.whereis(WordChain.GameServer) #Se comprueba que el módulo sigue vivo pero tiene un pid diferente

# SOLO PARA EL SERVIDOR HTTP (Plug.Cowboy)
ref = WordChain_Router_4000 #Referencia al socket del puerto 4000 (puerto por defecto)
Plug.Cowboy.shutdown(ref) #Cierra el puerto
#Buscamos el pid del servidor web
WordChain.MySupervisor.list_processes()
#Nos devuelve la especificacion de nuestro arbol de supervisión:
#%{
#  #PID<0.247.0> => {WordChain.Server, :start_link, [[name: WordChain.Server]]},
#  #PID<0.248.0> => {WordChain.LoginServer, :start_link, [[name: WordChain.LoginServer]]},
#  #PID<0.249.0> => {WordChain.GameServer, :start_link, [[name: WordChain.GameServer]]},
#  #PID<0.250.0> => {WordChain.Repository, :start_link, [[name: WordChain.Repository]]},
#  #PID<0.256.0> => {Plug.Cowboy, :http,
#   [WordChain.Router, [], [ref: WordChain_Router_4000]]}
#}
pid = pid(0,256,0) #Porque este es el pid que nos ha indicado el supervisor que le corresponde a Cowboy
Process.exit(pid, :kill) #Mata el proceso
WordChain.MySupervisor.list_processes() #Se comprueba que el módulo sigue vivo pero tiene un pid diferente

#Tambien se puede simular un crasheo no catrastrófico 
#Sin cerrar el puerto conseguimos el pid
Process.exit(pid, :normal)
#De esta manera ranch cierra su puerto por si mismo y nuestro supervisor puede reiniciar el proceso sin mayor problema
```
Credenciales de PostgreSQL

ID: cfb90dd3-5abc-4a77-baa0-5017b6d08537

Host: postgres-free-tier-v2020.gigalixir.com

Port: 5432

Username: cfb90dd3-5abc-4a77-baa0-5017b6d08537-user

Password: pw-43d07f2b-f743-4e03-a6d6-93c59485e75e

Database: cfb90dd3-5abc-4a77-baa0-5017b6d08537


TODO: 
- **HECHO** Resolver bugs de tíldes y Ñs - (simplemente las filtra, ya que el template engine Eex no las soporta)
- **HECHO** Conseguir meter el controlador del router (Plug.Cowboy) en nuestro custom supervisor
- **HECHO** Pasars la 1000 palabras del archivo a la base de datos y usarlas en el juego
- **HECHO** Comentarios para generar HexDocs (mix docs) 
- **HECHO** Documentación C4
- **HECHO** Poner todos los nombres en la meta description
- **HECHO** (OPT) Añadir funcionalidad, existe la palabra (API o parsear html)
- Testear la aplicación
    - Tests de unidad:        
        - ***HECHO*** Supervisor
        - ***HECHO*** Repository
    - Tests de integración:
        - ***HECHO*** Game Server
        - ***HECHO*** Login Server
    - Tests de sistema:
        - ***HECHO*** Registros
        - ***HECHO*** Inicios de sesión
        - ***HECHO*** Respuestas de palabras
