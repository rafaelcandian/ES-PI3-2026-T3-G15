// Autor: Arthur Valerio De Santi
// RA: 25006924
// Descrição: Inicialização e exportação da instância do Firestore.

// =============================================================================
// PROPÓSITO DO ARQUIVO:
// Centraliza a criação e exportação da instância do banco de dados Firestore.
// Ao invés de chamar getFirestore() em cada arquivo individualmente,
// todos os módulos importam o objeto `db` deste arquivo.
// Isso garante que apenas uma instância do banco seja criada (singleton),
// reduzindo overhead de conexão e facilitando manutenções futuras
// (ex: troca de configuração ou banco de dados).
// =============================================================================

import {getFirestore} from "firebase-admin/firestore";

// INSTÂNCIA GLOBAL DO FIRESTORE:
// `db` é o ponto de acesso único ao banco de dados Firestore do projeto.
// Deve ser importado por todos os repositórios e handlers que precisam
// ler ou escrever dados no banco.
export const db = getFirestore();
