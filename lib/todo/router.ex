defmodule Todo.Router do
  use Plug.Router
  require EEx

  # alias Todo.Server TODO: usar alias para todos los modulos con prefijo Todo.

  @template "priv/static/template.html.eex"
  @template_login "priv/static/template_login.html.eex"

  # Routing de contenido statico (css, js)
  plug(Plug.Static, from: :todo, at: "/static")
  plug(:match)
  plug(:dispatch)

  get "/" do
    response = EEx.eval_file(@template_login, error: "")
    send_resp(conn, 200, response)
  end

  get "/service-worker.js" do
    send_file(
      conn
      |> put_resp_header("Content-Type", "text/javascript"),
      200,
      "service-worker.js"
    )
  end

  post "/login" do
    response =
      read_login(conn)
      # Por que aqui tengo que usar el prefijo Todo? Y no cuando llamo solo a Server?
      |> Todo.LoginServer.check_login()

    built_response =
      case response["state"] do
        "no_user" ->
          IO.puts("No user")

          response
          |> build_error

        "incorrect_pwd" ->
          IO.puts("Incorrect_pwd")

          response
          |> build_error

        "ok" ->
          {historial, siguiente} = Todo.GameServer.first()

          response
          |> Map.put("historial", historial)
          |> Map.put("siguiente", siguiente)
          |> build_response
      end

    send_resp(conn, 200, built_response)
  end

  post "/respuesta" do
    response =
      read_question(conn)
      # Por que aqui tengo que usar el prefijo Todo? Y no cuando llamo solo a Server?
      |> Todo.LoginServer.check_login()

    IO.inspect(response)

    built_response =
      case response["state"] do
        "no_user" ->
          IO.puts("No user")

          response
          |> build_error

        "incorrect_pwd" ->
          IO.puts("Incorrect_pwd")

          response
          |> build_error

        "ok" ->
          {{historial, siguiente}, error}=
          case Todo.GameServer.check_previous(response.question, response.history) do
            "invalid_response" ->
              {{response.history, response.history |> Enum.at(0)}, "invalid_response"}
            "correct" ->
              {Todo.GameServer.answer(response.question, response.history), ""}
          end
          

          response
          |> Map.put("historial", historial)
          |> Map.put("siguiente", siguiente)
          |> Map.put("error", error)
          |> build_response
      end

    send_resp(conn, 200, built_response)
  end

  match(_, do: send_resp(conn, 404, "This is not the page you are looking for"))

  defp read_login(conn) do
    {:ok, body, _conn} = read_body(conn)
    split_body = String.split(body, "&")

    "username=" <> username =
      Enum.at(split_body, 0)
      |> String.replace("+", " ")

    "pwd=" <> pwd =
      Enum.at(split_body, 1)
      |> String.replace("+", " ")

    %{username: username, pwd: pwd}
  end

  defp read_question(conn) do
    {:ok, body, _conn} = read_body(conn)
    split_body = String.split(body, "&")
    IO.inspect(body)
    IO.inspect(split_body)

    "username=" <> username =
      Enum.at(split_body, 0)
      |> String.replace("+", " ")

    "pwd=" <> pwd =
      Enum.at(split_body, 1)
      |> String.replace("+", " ")

    "question=" <> question =
      Enum.at(split_body, 2)
      |> String.replace("+", " ")

    history_list =
      if split_body
         |> length() < 4 do
        []
      else
        {_, list} =
          split_body
          |> List.pop_at(0)

        {_, list} =
          list
          |> List.pop_at(0)

        {_, list} =
          list
          |> List.pop_at(0)
        list
        |> Enum.map(fn entry ->
          Enum.at(String.split(entry, "="), 1)
        end)
      end

    %{username: username, pwd: pwd, question: question, history: history_list}
  end

  defp build_error(response) do
    EEx.eval_file(@template_login, todos: [], error: response["state"])
  end

  defp build_response(response) do
    EEx.eval_file(@template,
      historial: response["historial"],
      siguiente: response["siguiente"],
      credenciales: [
        response.username,
        response.pwd
      ],
      error: response["error"]
    )
  end
end
