defmodule WordChain.Router do
  @moduledoc """
    Módulo encargado de redirigir las peticiones recibidas a los distintos módulos de la aplicación.
  """
  use Plug.Router
  use Plug.ErrorHandler
  require EEx

  # alias WordChain.Server TODO: usar alias para todos los modulos con prefijo WordChain.

  @template "priv/static/template.html.eex"
  @template_login "priv/static/template_login.html.eex"
  @template_signup "priv/static/template_signup.html.eex"
  @template_win "priv/static/template_win.html.eex"

  # Routing de contenido statico (css, js)
  plug(Plug.Static, from: :word_chain, at: "/static")
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

  get "/signup" do
    response = EEx.eval_file(@template_signup, error: "")
    send_resp(conn, 200, response)
  end

  post "/signup" do
    response =
      read_login(conn)
      |> WordChain.LoginServer.check_login()

    built_response =
      case response["state"] do
        "no_user" ->
          IO.puts("No user")

          user = %{"username" => response.username, "pwd" => response.pwd}
          WordChain.LoginServer.insert_user(user)

          {historial, siguiente} = WordChain.GameServer.first()

          response
          |> Map.put("historial", historial)
          |> Map.put("siguiente", siguiente)
          |> build_response

        state when state == "ok" or state == "incorrect_pwd" ->
          %{response | "state" => "username taken"}
          |> build_error_signup
      end

    send_resp(conn, 200, built_response)
  end

  post "/login" do
    response =
      read_login(conn)
      # Por que aqui tengo que usar el prefijo WordChain? Y no cuando llamo solo a Server?
      |> WordChain.LoginServer.check_login()

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
          {historial, siguiente} = WordChain.GameServer.first()

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
      # Por que aqui tengo que usar el prefijo WordChain? Y no cuando llamo solo a Server?
      |> WordChain.LoginServer.check_login()

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
          {{historial, siguiente}, error} =
            case WordChain.GameServer.check_previous(response.question, response.history) do
              "invalid_response" ->
                {{response.history, response.history |> Enum.at(0)}, "invalid_response"}

              "already_used" ->
                {{response.history, response.history |> Enum.at(0)}, "already_used"}

              "correct" ->
                {WordChain.GameServer.answer(response.question, response.history), ""}
            end

          case siguiente do
            "" -> 
              EEx.eval_file(@template_win)
            _ -> 
              response
                |> Map.put("historial", historial)
                |> Map.put("siguiente", siguiente)
                |> Map.put("error", error)
                |> build_response
          end
      end

    send_resp(conn, 200, built_response)
  end

  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    send_resp(conn, 200, EEx.eval_file(@template_win))
  end

  match(_, do: send_resp(conn, 404, "This is not the page you are looking for"))

  defp read_login(conn) do
    {:ok, body, _conn} = read_body(conn)
    split_body = String.split(body, "&")

    "username=" <> username =
      Enum.at(split_body, 0)
      |> String.replace("+", " ")
      |> sanitize_string()

    "pwd=" <> pwd =
      Enum.at(split_body, 1)
      |> String.replace("+", " ")
      |> sanitize_string()

    %{username: username, pwd: pwd}
  end

  defp sanitize_string(word) do
    word
    |> String.replace("%C3", "")
    |> String.replace("%A1", "a")
    |> String.replace("%A9", "e")
    |> String.replace("%AD", "i")
    |> String.replace("%B3", "o")
    |> String.replace("%BA", "u")
    |> String.replace("%B1", "ñ")
    |> String.replace("%81", "A")
    |> String.replace("%89", "E")
    |> String.replace("%8D", "I")
    |> String.replace("%93", "O")
    |> String.replace("%9A", "U")
    |> String.replace("%91", "Ñ")
  end

  defp read_question(conn) do
    {:ok, body, _conn} = read_body(conn)
    split_body = String.split(body, "&")
    IO.inspect(body)
    IO.inspect(split_body)

    "username=" <> username =
      Enum.at(split_body, 0)
      |> String.replace("+", " ")
      |> sanitize_string()

    "pwd=" <> pwd =
      Enum.at(split_body, 1)
      |> String.replace("+", " ")
      |> sanitize_string()

    "question=" <> question =
      Enum.at(split_body, 2)
      |> String.replace("+", "")

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
          |> sanitize_string()
        end)
      end

    %{username: username, pwd: pwd, question: question, history: history_list}
  end

  defp build_error(response) do
    EEx.eval_file(@template_login, error: response["state"])
  end

  defp build_error_signup(response) do
    EEx.eval_file(@template_signup, error: response["state"])
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
