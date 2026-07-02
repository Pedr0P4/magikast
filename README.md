# Magikast 🧙‍♂️✨

**Magikast** é um jogo multiplayer de arena focado em combate de magos em tempo real. Desenvolvido com **Godot Engine 4** no frontend e um servidor em **Spring Boot (Java)** no backend para persistência de estatísticas e autenticação dos jogadores.

---

## 🎮 Sobre o Jogo
Em Magikast, os jogadores se enfrentam em uma arena fechada. O objetivo é derrotar seu oponente coletando poderes gerados aleatoriamente pelo mapa e disparando feitiços precisos.

### Principais Características
* **Autenticação de Jogadores:** Registro e Login integrados diretamente com o backend local.
* **Histórico de Estatísticas:** Acompanhamento de partidas jogadas, vitórias, streak atual e recorde de streak (max streak) gravados de forma segura.
* **Combate com Elementos:**
  * 🔥 **Bola de Fogo (Fireball):** Causa grande dano e aplica queimação contínua (burn effect).
  * ⚡ **Raio Elétrico (Electric Bolt):** Disparo rápido que causa dano médio e paralisa temporariamente o oponente.
* **Indicador Visual de Mira (Cristal de Poder):** Mostra o elemento equipado e pulsa/apaga de acordo com o tempo de recarga (cooldown) do feitiço.

---

## 🛠️ Tecnologias Utilizadas
* **Frontend:** Godot Engine 4.7 (GL Compatibility / DirectX 12)
* **Linguagem Frontend:** GDScript
* **Backend:** Java 17+ / Spring Boot
* **Banco de Dados:** Banco local baseado em JSON (`accounts.json`)
* **Gerenciador de Dependências Backend:** Gradle

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
* [Godot Engine 4](https://godotengine.org/) instalado.
* [Java JDK 17](https://www.oracle.com/java/technologies/downloads/) ou superior instalado e configurado nas variáveis de ambiente.

---

### Passo 1: Iniciar o Servidor Backend
O backend gerencia os logins e salva o progresso e estatísticas de jogo no arquivo `accounts.json`.

1. Abra o terminal na pasta raiz do projeto.
2. Navegue até a pasta `backend`:
   ```bash
   cd backend
   ```
3. Inicie o servidor Spring Boot usando o wrapper do Gradle:
   * **No Windows:**
     ```cmd
     gradlew.bat bootRun
     ```
   * **No Linux/macOS:**
     ```bash
     ./gradlew bootRun
     ```
4. O backend estará ativo no endereço `http://localhost:8080`.

---

### Passo 2: Executar o Jogo
Para testar o modo multiplayer, você precisará de duas instâncias do jogo rodando ao mesmo tempo.

#### Opção A: Pelo Editor do Godot (Recomendado)
1. Abra o Godot Engine e importe o projeto apontando para a pasta raiz (`magikast`).
2. No canto superior direito do editor, mude a configuração de execução para abrir múltiplas instâncias:
   * Clique em **Debug** > **Run Multiple Instances** > selecione **2 Instances**.
3. Pressione **F5** (ou o botão Play) para rodar os dois clientes.

#### Opção B: Exportando o Jogo
1. No editor do Godot, acesse **Project** > **Export**.
2. Exporte o jogo para o sistema operacional de sua preferência.
3. Execute o arquivo executável gerado duas vezes.

---

## 🕹️ Como Jogar

1. **Criar Conta:** Na tela inicial de ambos os clientes, registre duas contas diferentes (ex: `Pedroca` e `Cecizita`).
2. **Logar:** Faça login com as contas criadas.
3. **Conectar na Sala:**
   * **Host (Jogador 1):** Clique em **Criar Sala**. Você entrará no lobby de espera.
   * **Client (Jogador 2):** Digite o IP da máquina host (ou `127.0.0.1` para testar localmente) e clique em **Entrar na Sala**.
4. **Começar:** Quando ambos os jogadores estiverem conectados no lobby, o Host clica em **Começar Partida**.
5. **Combater:**
   * Movimente-se usando as teclas `W`, `A`, `S`, `D`.
   * Aponte com o mouse para mirar.
   * Encoste nos orbes de poder que surgem na tela para coletar um feitiço.
   * Clique com o **Botão Esquerdo do Mouse** para atacar.
   * Fique de olho no cristal colorido na ponta da sua mira para saber quando seu poder saiu da recarga!

---

## 📁 Estrutura de Pastas
* `/assets/` - Recursos visuais, sprites de efeitos, orbes e ícones.
* `/backend/` - Servidor Spring Boot em Java com regras de negócios de login e pontuações.
* `/resources/` - Recursos do Godot, como definições de poderes (cooldown, dano).
* `/scenes/` - Cenas do jogo (Menús, Lobby, Arena Principal e Projéteis).
* `/scripts/` - Scripts GDScript responsáveis pelo comportamento dos elementos, rede e integrações com o backend.
