defmodule ProjectDocker do

  def initiate(node, nnode) do
    send(node, {:init, nnode})
  end

  def addFile({id, machine}, filename) do
    send({id, machine}, {:addFile, {filename}})
  end

  def lookFile({id, machine}, filename) do
    send({id, machine}, {:requestFile, filename, self()})
  end

end
