defmodule Communication do

  ###=============================================================================
  ### Basics inter-node communication
  ###=============================================================================

  def ringSearch (nodes, filename) do
    # ask the other node to search a given file
    # nodes : v0.1 one node to ask
    # filename : file identifier

    send (nodes, filename)
  end

end
