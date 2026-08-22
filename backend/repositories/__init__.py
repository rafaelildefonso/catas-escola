# Camada Repository — acesso complexo ao banco de dados
#
# Aqui ficam as consultas que vão além do CRUD básico dos Models
# (WHERE, ORDER BY, JOIN, GROUP BY, agregações, busca e paginação).
# Em PostgreSQL (producao/Supabase) as consultas delegam para as
# procedures definidas em migrations/018_procedures_relatorios.sql.
# Em SQLite (dev/teste) executam consulta inline equivalente.