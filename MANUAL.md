# mri_Qspotlights — Manual

Ferramenta de admin para criar e remover holofotes (spotlights) sincronizados no mundo, posicionados por raycast a partir da câmera.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Permissões (ACE)](#permissões-ace)
4. [Comandos](#comandos)
5. [Como criar um holofote](#como-criar-um-holofote)
6. [Como remover um holofote](#como-remover-um-holofote)
7. [Persistência](#persistência)
8. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
9. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `ox_lib` | Sim | Callbacks, `raycast.cam`, `inputDialog`, `showTextUI`, `addCommand` |
| `ox_core` | Não | Único ponto de acoplamento a framework — ver observação |

O recurso é, na prática, standalone: a única dependência de framework é o handler de `ox:playerLoaded` em `client/main.lua`, que carrega a lista de holofotes quando o jogador entra. Em servidores QBox/QBCore esse evento não dispara, então o jogador só recebe os holofotes existentes depois que alguém criar ou remover um (o que dispara um broadcast para todos). Para corrigir, troque esse handler pelo evento de load do seu framework.

---

## Instalação

1. Copie a pasta `mri_Qspotlights` para `resources/`.
2. Adicione ao `server.cfg`:
   ```
   ensure mri_Qspotlights
   ```
3. Libere a ACE do comando (veja abaixo).

Não há SQL nem itens de inventário.

---

## Permissões (ACE)

O comando `/spotlight` é registrado via `lib.addCommand` com `restricted = 'group.admin'`. O `ox_lib` cria a ACE `command.spotlight` e a concede ao grupo indicado, então basta que o jogador pertença a `group.admin`:

```
add_principal identifier.license:<license> group.admin
```

---

## Comandos

| Comando | Permissão | Descrição |
|---|---|---|
| `/spotlight` | `group.admin` | Entra no modo de criação de um novo holofote |
| `/spotlight 1` | `group.admin` | Entra no modo de remoção (apaga o holofote mais próximo do ponto mirado) |

---

## Como criar um holofote

1. Execute `/spotlight`.
2. Mire com a câmera. Uma linha e uma esfera azul indicam o ponto atingido pelo raycast. Pressione **E** para fixar a **posição inicial** (origem da luz).
3. Mire novamente e pressione **E** para fixar a **segunda posição** — o vetor entre os dois pontos define a direção do facho.
4. Preencha o formulário que abre:

| Campo | Tipo | Descrição |
|---|---|---|
| Cor | color (rgb) | Cor do facho |
| Distância | number | Alcance da luz |
| Brilho | number | Intensidade |
| Dureza | number | Nitidez da borda do facho |
| Raio | number | Abertura do cone |

O holofote é criado imediatamente e sincronizado com todos os jogadores online.

---

## Como remover um holofote

1. Execute `/spotlight 1`.
2. Todos os holofotes existentes passam a ser desenhados como esferas azuis.
3. Mire em uma esfera (raio de 0,5 m do ponto de origem) e pressione **E** para apagar.

Executar `/spotlight 1` novamente alterna o modo de remoção para desligado.

---

## Persistência

A lista de holofotes vive em uma tabela em memória no `server/main.lua`. **Não há gravação em disco ou banco de dados** — os holofotes são perdidos ao reiniciar o recurso ou o servidor.

---

## Entrypoints para outros recursos

### Callback `qw_spotlights:getSpotlights`

Retorna a lista completa de holofotes atualmente registrados no servidor.

```lua
local spotlights = lib.callback.await('qw_spotlights:getSpotlights', 100)
```

### Evento `qw_spotlights:server:sync`

Substitui a lista inteira no servidor e faz broadcast para todos os clients. É o evento usado pelo client ao criar ou remover um holofote.

```lua
TriggerServerEvent('qw_spotlights:server:sync', spotlightData)
```

### Evento `qw_spotlights:client:sync`

Disparado pelo servidor para todos os clients com a lista atualizada.

Cada entrada da lista tem o formato:

```lua
{
    initalCoords = vector3,          -- origem da luz
    secondCoords = vector3,          -- ponto de mira usado para calcular a direção
    direction    = vector3,          -- secondCoords - initalCoords
    data = {
        rgb        = { x = 0, y = 0, z = 0 },  -- componentes R, G, B
        distance   = number,
        brightness = number,
        hardness   = number,
        radius     = number,
    }
}
```

---

## Estrutura de arquivos

```
mri_Qspotlights/
├── client/
│   ├── main.lua     — thread de desenho (DrawSpotLight), modo de remoção, sync inicial
│   └── utils.lua    — raycast de posicionamento, formulário de criação, remoção do mais próximo
├── server/
│   └── main.lua     — lista em memória, callback de leitura, broadcast, comando /spotlight
└── fxmanifest.lua
```
