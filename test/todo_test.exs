defmodule WordChainTest do
  use ExUnit.Case
  doctest WordChain

  test "greets the world" do
    assert WordChain.hello() == :world
  end

  test "UserRepositoryTest" do
    newUser = %{"username" => "paco", "pwd" => "bailaor"}
    statement = "DELETE FROM users WHERE username = '#{newUser["username"]}'"

    assert WordChain.Repository.select_user("admo") == []
    assert WordChain.Repository.select_user("admin") != []
    WordChain.Repository.insert_user(newUser)
    assert WordChain.Repository.select_user("paco") != []
    WordChain.Repository.query(statement)
    assert WordChain.Repository.select_user("paco") == []
    # IO.puts "User repository test successful!"
  end

  test "Word Repository Unit Test" do
    repo_rand_words = WordChain.Repository.select_words()
    word = Enum.random(repo_rand_words)

    repo_word =
      WordChain.Repository.select_words_by_letter(word)
      |> Enum.random()

    assert word != ""
    assert word |> String.last() == repo_word |> String.first()

    word = "_testing_word"
    find_word_st = "SELECT word FROM words WHERE word = '#{word}'"
    insert_word_st = "INSERT INTO words(word) VALUES ('#{word}')"
    delete_word_st = "DELETE FROM words WHERE word = '#{word}'"
    WordChain.Repository.query(insert_word_st)
    assert WordChain.Repository.query(find_word_st) != []
    WordChain.Repository.query(delete_word_st)
    assert WordChain.Repository.query(find_word_st) == []
  end

  test "Login Server Unit Test" do
    user = %{:username => "admin", :pwd => "admin"}
    no_user = %{:username => "admo", :pwd => "admin"}
    user_incorrect_pwd = %{:username => "admin", :pwd => "admo"}

    user = WordChain.LoginServer.check_login(user)
    no_user = WordChain.LoginServer.check_login(no_user)
    user_incorrect_pwd = WordChain.LoginServer.check_login(user_incorrect_pwd)

    assert Map.fetch(user, "state") |> elem(1) == "ok"
    assert Map.fetch(no_user, "state") |> elem(1) == "no_user"
    assert Map.fetch(user_incorrect_pwd, "state") |> elem(1) == "incorrect_pwd"
  end

  test "Supervisor Test" do
    # Supervisor on Game/LoginServers/Repo shutdown.
    pid_game = Process.whereis(WordChain.GameServer)
    pid_login = Process.whereis(WordChain.LoginServer)
    pid_repo = Process.whereis(WordChain.Repository)

    assert pid_game != nil
    assert pid_login != nil
    assert pid_repo != nil

    Process.exit(pid_game, :kill)
    Process.exit(pid_login, :kill)
    Process.exit(pid_repo, :kill)
    :timer.sleep(100)
    assert Process.whereis(WordChain.GameServer) != nil
    assert Process.whereis(WordChain.LoginServer) != nil
    assert Process.whereis(WordChain.Repository) != nil
  end

  test "Game Server Unit Test" do
    assert WordChain.GameServer.first() != nil
    assert WordChain.GameServer.check_previous("operación", ["nulo"]) == "correct"
    assert WordChain.GameServer.check_previous("operación", ["ptr", "nulo"]) == "invalid_response"
    assert WordChain.GameServer.answer("operacion", ["nulo"]) |> elem(1) |> String.at(0) == "n"
  end

  test "System Test" do
    # Test correct login.
    login = "username=admin&pwd=admin"

    {:ok, response} =
      HTTPoison.post("http://localhost:4000/login", "#{login}", [
        {"Content-Type", "application/x-www-form-urlencoded"}
      ])

    assert Map.fetch(response, :status_code) == {:ok, 200}

    # Test incorrect username.
    login = "username=admo&pwd=admin"

    {:ok, response} =
      HTTPoison.post("http://localhost:4000/login", "#{login}", [
        {"Content-Type", "application/x-www-form-urlencoded"}
      ])

    assert Map.fetch(response, :status_code) == {:ok, 200}
    {:ok, html_no_user} = Map.fetch(response, :body)
    {:ok, document_no_user} = Floki.parse_document(html_no_user)

    assert Floki.find(document_no_user, ".error") |> List.first() |> elem(2) |> List.first() ==
             "no_user"

    # Test incorrect pwd.
    login = "username=admin&pwd=admo"

    {:ok, response} =
      HTTPoison.post("http://localhost:4000/login", "#{login}", [
        {"Content-Type", "application/x-www-form-urlencoded"}
      ])

    assert Map.fetch(response, :status_code) == {:ok, 200}
    {:ok, html_inc_pwd} = Map.fetch(response, :body)
    {:ok, document_inc_pwd} = Floki.parse_document(html_inc_pwd)

    assert Floki.find(document_inc_pwd, ".error") |> List.first() |> elem(2) |> List.first() ==
             "incorrect_pwd"

    # Test singup.
    signup = "username=test&pwd=test"

    {:ok, response} =
      HTTPoison.post("http://localhost:4000/signup", "#{signup}", [
        {"Content-Type", "application/x-www-form-urlencoded"}
      ])

    assert Map.fetch(response, :status_code) == {:ok, 200}
    delete_st = "DELETE FROM users WHERE username = 'test'"
    find_st = "SELECT user FROM users WHERE username = 'test'"

    {:ok, response} =
      HTTPoison.post("http://localhost:4000/login", "#{signup}", [
        {"Content-Type", "application/x-www-form-urlencoded"}
      ])

    assert Map.fetch(response, :status_code) == {:ok, 200}
    WordChain.Repository.query(delete_st)
    assert WordChain.Repository.query(find_st) == []

    # Test singup used username.
    signup = "username=admin&pwd=test"

    {:ok, response} =
      HTTPoison.post("http://localhost:4000/signup", "#{signup}", [
        {"Content-Type", "application/x-www-form-urlencoded"}
      ])

    assert Map.fetch(response, :status_code) == {:ok, 200}
    {:ok, html_inc_pwd} = Map.fetch(response, :body)
    {:ok, document_inc_pwd} = Floki.parse_document(html_inc_pwd)

    assert Floki.find(document_inc_pwd, ".error") |> List.first() |> elem(2) |> List.first() ==
             "username taken"

    # Test valid answer
    body = "username=admin&pwd=admin&question=andamio&entrada=encuentra&entrada=suficiente"

    {:ok, response} =
      HTTPoison.post("http://localhost:4000/respuesta", "#{body}", [
        {"Content-Type", "application/x-www-form-urlencoded"}
      ])

    assert Map.fetch(response, :status_code) == {:ok, 200}
    {:ok, html} = Map.fetch(response, :body)
    {:ok, document} = Floki.parse_document(html)
    assert Floki.find(document, ".error") |> List.first() |> elem(2) == []

    # Test invalid answer
    body = "username=admin&pwd=admin&question=vere&entrada=suficiente"

    {:ok, response} =
      HTTPoison.post("http://localhost:4000/respuesta", "#{body}", [
        {"Content-Type", "application/x-www-form-urlencoded"}
      ])

    assert Map.fetch(response, :status_code) == {:ok, 200}
    {:ok, html} = Map.fetch(response, :body)
    {:ok, document} = Floki.parse_document(html)

    assert Floki.find(document, ".error") |> List.first() |> elem(2) |> List.first() ==
             "invalid_response"

    # Test duplicated answer
    body = "username=admin&pwd=admin&question=origen&entrada=equipo&entrada=nene&entrada=origen"

    {:ok, response} =
      HTTPoison.post("http://localhost:4000/respuesta", "#{body}", [
        {"Content-Type", "application/x-www-form-urlencoded"}
      ])

    assert Map.fetch(response, :status_code) == {:ok, 200}
    {:ok, html} = Map.fetch(response, :body)
    {:ok, document} = Floki.parse_document(html)

    assert Floki.find(document, ".error") |> List.first() |> elem(2) |> List.first() ==
             "already_used"
  end
end
