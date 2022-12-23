To make a 3 nodes circle:
# Create network and connect multiple Docker containers

# 1. Create bridge network
docker network create elixir-net
docker network inspect elixir-net

# 2. Start Docker containers in network
# a) First terminal
docker run --rm -it --name elixir1 -h host1 --net elixir-net elixir /bin/bash
# b) Second terminal
docker run --rm -it --name elixir2 -h host2 --net elixir-net elixir /bin/bash
# c) Third terminal
docker run --rm -it --name elixir3 -h host3 --net elixir-net elixir /bin/bash
# d) Forth terminal
docker run --rm -it --name elixir4 -h host4 --net elixir-net elixir /bin/bash

# 3. Run elixir
# a) First terminal
iex --sname foo --cookie secret
# b) Second terminal
iex --sname bar --cookie secret
# c) Third terminal
iex --sname bof --cookie secret
# d) Forth terminal
iex --sname dis --cookie secret

# 4. Run program
# a) First terminal
Node.ping(:bar@host2)
# b) Third terminal
Node.ping(:bar@host2)
# c) Forth terminal
Node.ping(:bar@host2)

# 4.1 Copy file (assuming file fifo.erl is in the local directory)
docker cp src/backend/communication.ex elixir1:communication.ex
docker cp src/backend/communication.ex elixir2:communication.ex
docker cp src/backend/communication.ex elixir3:communication.ex
docker cp src/backend/nodes.ex elixir1:nodes.ex
docker cp src/backend/nodes.ex elixir2:nodes.ex
docker cp src/backend/nodes.ex elixir3:nodes.ex
docker cp src/backend/dispatcher.ex elixir4:dispatcher.ex

# 4.2 Compile DB program
# a) First, Second and Third terminal
c("communication.ex")
c("nodes.ex")
# b) Second terminal
c("dispatcher.ex")

# 4.3 Run DB program
# a) Forth terminal
Dispatcher.initiate(:dis@host4)
# b) First terminal
Process.register(Nodee.node_init({:n1, :foo@host1}, {:dispatcher, :dis@host4}), :n1)
# c) Second terminal
Process.register(Nodee.node_init({:n2, :bar@host2}, {:dispatcher, :dis@host4}), :n2)
# d) Third terminal
Process.register(Nodee.node_init({:n3, :bof@host3}, {:dispatcher, :dis@host4}), :n3)

# 4.4 Usage in Forth terminal
Dispatcher.addFile("SampleFile1")
Dispatcher.addFile("SampleFile2")
Dispatcher.lookFile("SampleFile1")

# 5. Clean up
docker network rm elixir-net
