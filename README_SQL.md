**Prática 3 — Executando o script SQL**

- **Arquivo**: `sql/pratica-3.sql`

**Requisitos**:
- Ter o PostgreSQL instalado (cliente `psql`) ou usar um contêiner Docker com Postgres.
- Acesso a um banco de dados (p.ex. `postgres` ou um DB novo).

**Executar o script com `psql`**

1) Criar um banco (opcional):

```bash
createdb posto_combustivel
```

2) Executar o script (substitua `posto_combustivel` pelo nome do seu DB):

```bash
psql -d posto_combustivel -f sql/pratica-3.sql
```

3) Consultas rápidas no `psql` após executar:

```sql
-- Ver resumo por combustível
SELECT * FROM resumo_venda_combustivel ORDER BY valor_vendido DESC;

-- Listar combustíveis com estoque > 1000
SELECT combustivel_id, nome, estoque_l FROM combustivel WHERE estoque_l > 1000 ORDER BY estoque_l DESC;

-- Total vendido por funcionário no dia 2025-11-01
SELECT f.nome, SUM(v.total) AS total_funcionario
FROM funcionario f
JOIN venda v ON v.funcionario_id = f.funcionario_id
WHERE v.data_hora >= '2025-11-01 00:00:00-03' AND v.data_hora < '2025-11-02 00:00:00-03'
GROUP BY f.nome
ORDER BY total_funcionario DESC;
```

**Executar com Docker (rápido)**

1) Subir um container Postgres temporário:

```bash
docker run --name pg-pratica -e POSTGRES_PASSWORD=senha -e POSTGRES_DB=posto_combustivel -p 5432:5432 -d postgres:15
```

2) Copiar o script para o container e executar (ou usar `psql` local apontando para `localhost`):

```bash
# se tiver psql local, basta executar contra localhost:5432
psql "postgresql://postgres:senha@localhost:5432/posto_combustivel" -f sql/pratica-3.sql
```

3) Parar/remover o container quando terminar:

```bash
docker stop pg-pratica && docker rm pg-pratica
```

**Observações**:
- O script usa `ON CONFLICT DO NOTHING` nos `INSERT` para permitir reexecução sem erro de duplicidade.
- A `VIEW` `resumo_venda_combustivel` inclui `NULLIF(...,0)` para evitar divisão por zero.
- Se preferir limpar o esquema, use os comandos comentados ao final do script (`DROP TABLE ...`).

**Próximos passos (opcionais)**:
- Quer que eu rode o script aqui no contêiner do devcontainer? (preciso de permissão para usar Docker/serviço local)
- Gerar um arquivo `docker-compose.yml` para facilitar a execução do Postgres localmente.

**Iniciar com `docker-compose` (recomendado)**

1) Subir o serviço usando o `docker-compose.yml` já incluído no repositório:

```bash
docker-compose up -d
```

2) O `docker-compose` mapeia a pasta `./sql` para `/docker-entrypoint-initdb.d` no container, portanto o script `sql/pratica-3.sql` será executado automaticamente na primeira inicialização do volume (somente quando o volume de dados estiver vazio). Para aplicar manualmente depois, use:

```bash
# se tiver psql local
psql "postgresql://postgres:senha@localhost:5432/posto_combustivel" -f sql/pratica-3.sql
```

3) Parar e remover o ambiente quando terminar:

```bash
docker-compose down -v
```

Use a senha `senha` fornecida no `docker-compose.yml` ou altere-a conforme necessário.

**Uso rápido com `run.sh`**

Criei um utilitário `./run.sh` na raiz do repositório para facilitar os comandos comuns.

- `./run.sh up` — sobe o Postgres em background (equivalente a `docker-compose up -d`).
- `./run.sh apply` — aplica o script `sql/pratica-3.sql` no banco (tenta dentro do container e também via `psql` local).
- `./run.sh psql` — abre um shell `psql` conectado ao banco `posto_combustivel`.
- `./run.sh status` — mostra o status dos serviços (`docker-compose ps`).
- `./run.sh logs` — segue os logs do serviço de banco.
- `./run.sh down` — para e remove containers e volumes (`docker-compose down -v`).

Exemplo rápido:

```bash
./run.sh up
./run.sh apply
./run.sh psql
```

O script já está marcado como executável (`chmod +x ./run.sh`).

---
Arquivo criado por suporte: `README_SQL.md` — o próximo passo é executar os comandos caso queira testar o banco.