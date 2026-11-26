# Atlas das Brasas

RPG educativo de fantasia em português, desenvolvido em Godot 4. A campanha percorre seis regiões e reúne 29 atividades integradas à exploração e ao combate em tempo real.

- **Projeto Godot** — importe [project.godot](AtlasDasBrasas/project.godot) e pressione F5. A versão usada no desenvolvimento foi a 4.7.2. Os controles e as instruções de teste estão no [guia do projeto](AtlasDasBrasas/LEIA-ME.txt).
- **Linux x86-64** — extraia o [pacote do jogo](distribuicao/AtlasDasBrasas-Linux-x86_64.zip) e execute `AtlasDasBrasas.x86_64`, mantendo o arquivo PCK ao lado do executável.
- **Navegador e celular** — a pasta [web](web/) contém a exportação para hospedagem estática, com controles de toque. Uma [edição em HTML único](distribuicao/AtlasDasBrasas-Celular.html) também acompanha o repositório.
- **Projeto compactado** — baixe o [ZIP dos fontes](distribuicao/AtlasDasBrasas-Projeto.zip) para editar o jogo sem clonar o repositório.
- **Arte** — as [ilustrações originais](arte-original/) acompanham os sprites, retratos, cenários e quadros de animação tratados no projeto.

## Rondas com a enfermeira Lia

Entre na oficina da Vila do Junco para conversar com Lia ou abra **Diário → Caderno de rondas**. Cada uma das seis regiões tem um posto identificado por uma flâmula turquesa. Após a orientação, marque o destino, explore a cena e decida com a equipe. O registro de cada ronda inclui o que foi observado, o cuidado realizado e a fonte oficial. As rondas são opcionais e podem ser revisitadas.

| Posto | Tema da ronda |
| --- | --- |
| Balsa do Junco | Higienização das mãos quando há sujeira visível |
| Pátio de Lume | Conferência de dois identificadores antes do cuidado |
| Cisterna de Ocre | Proteção da água potável depois de uma cheia |
| Pousada da Agulha | Prevenção de quedas com participação da pessoa |
| Viveiro da Nascente | Eliminação de criadouros de mosquitos |
| Posto de Basalto | Comunicação de uma urgência e acionamento do SAMU 192 |

A arte incorporada do Atlas.zip segue a ordem das onze pranchas do arquivo. As pranchas 1, 2, 4 e 9 compõem os quadros de movimento e ação do aventureiro. A prancha 3 fornece ícones para a mochila, as habilidades e a interface. As pranchas 5 e 7 fornecem edifícios e vegetação para o mundo. A prancha 8 ilustra as regiões do mapa. As pranchas 6 e 10 compõem guardiões e criaturas regionais. A prancha 11 fornece retratos e personagens para as conversas e os postos.

## Boletim das margens

O relógio avança durante a aventura. O HUD acompanha a hora e o tempo local. No mapa, escolha uma região e abra **Previsão da região** para consultar as condições atuais e os dois períodos seguintes. O boletim da região, quando aberto no interior de uma das seis escolas ou oficinas, permite passar o tempo até o amanhecer.

Na Vila do Junco, leia o quadro ao sul da oficina de Iria e aceite **A água dos viveiros**. A cooperativa precisa dos registros de chuva do Junco e de Lume para despachar uma carroça de rega. As leituras ficam disponíveis durante toda a missão. A entrega altera o viveiro escolhido e deixa um relatório no diário.

## Expansão local · Junco e rota até Lume

O mundo tem uma extensão de 9.216 × 4.096 pixels, com 96 setores distribuídos em seis territórios de 3.072 × 2.048 pixels. Os setores são unidades de carregamento. Os centros dos seis reinos conservam as posições locais da campanha. Um salvamento legado é convertido para o centro correspondente, preservando a posição nos interiores.

As fases 1 a 3 incluem a arquitetura de setores, a expansão de Junco e a rota terrestre até Lume. Para percorrê-la, atravesse o Junco a leste, passe pelo Porto dos Viajantes, pela Ponte das Duas Margens e pelo Entreposto do Livro. Enquanto a ponte central estiver em reparo, use a travessia ao norte ou ao sul. Leia as placas ao longo da estrada e consulte o **Mapa regional** para marcar um destino já visitado.

Os arredores de Junco incluem três povoados, a Fazenda das Colinas, as florestas, o Moinho Abandonado, o acampamento de caçadores e a Gruta do Veado. A cartografia inclui minimapa, zoom, regiões com áreas por descobrir e marcos de viagem. Os moradores dos povoados mudam de destino com o tempo. A cooperativa também mantém a oficina comunitária de Junco, com abrigo, fabricação em lote e evolução da espada curta.

Lume recebe o corredor e os primeiros arredores acadêmicos. Ocre, Agulha, Nascente e Basalto têm centros originais e setores transitáveis. O povoamento próprio dos novos setores desses territórios é trabalho das fases seguintes. As primeiras expedições do Arquipélago de Íris, das Terras Corrompidas e da Sétima Margem estão incluídas em mapas opcionais separados.

O teste de integração percorre a campanha, as rondas e a missão dos viveiros. Ele também dirige o aventureiro a pé de Junco até Lume, restaura salvamentos, testa a ponte e conclui as expedições de fronteira.
