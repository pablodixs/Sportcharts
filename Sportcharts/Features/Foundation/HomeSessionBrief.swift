//
//  HomeSessionBrief.swift
//  Sportcharts
//
//  Created by Codex on 15/06/26.
//

import FoundationModels

@Generable
struct HomeSessionBrief {
	@Guide(
		description:
			"Frase curta em português do Brasil sobre a principal história da última sessão, com no máximo 90 caracteres"
	)
	var headline: String

	@Guide(
		description:
			"Resumo objetivo da última sessão em 2 frases curtas, usando apenas os dados fornecidos"
	)
	var summary: String

	@Guide(
		description:
			"Até 3 destaques curtos da sessão, específicos e sem inventar fatos"
	)
	var highlights: [String]

	@Guide(
		description:
			"Três perguntas curtas e úteis que o usuário poderia fazer ao Vrum sobre esta sessão"
	)
	var smartQuestions: [String]
}
