# Traductions de Sudokuno. Source : français. Génère Sudokuno/Localizable.xcstrings.
# Usage (depuis la racine du dépôt) : python3 tools/translations.py
# Génère ios/Sudokuno/Localizable.xcstrings ET android/app/src/main/assets/i18n.json.
# Colonnes : en, nl, pt-PT, zh-Hans

import json, os, re, glob, sys

T = {
"%1$lld/%2$lld victoires en %3$@ pour débloquer": ("%1$lld/%2$lld wins in %3$@ to unlock", "%1$lld/%2$lld overwinningen in %3$@ om te ontgrendelen", "%1$lld/%2$lld vitórias em %3$@ para desbloquear", "在%3$@中获胜 %1$lld/%2$lld 次即可解锁"),
"%lld j": ("%lld d", "%lld d", "%lld d", "%lld 天"),
"%lld, donné": ("%lld, given", "%lld, gegeven", "%lld, dado", "%lld，题目给出"),
"%lld, gelé": ("%lld, frozen", "%lld, bevroren", "%lld, congelado", "%lld，已冻结"),
"%lld, non joué": ("%lld, not played", "%lld, niet gespeeld", "%lld, não jogado", "%lld，未完成"),
"%lld, réussi": ("%lld, completed", "%lld, voltooid", "%lld, concluído", "%lld，已完成"),
"%lld/81 cases · %@": ("%lld/81 cells · %@", "%lld/81 vakjes · %@", "%lld/81 casas · %@", "%lld/81 格 · %@"),
"Abandonner la partie en cours ?": ("Abandon the current game?", "Huidige partij opgeven?", "Abandonar o jogo atual?", "放弃当前游戏？"),
"Accueil": ("Home", "Start", "Início", "主页"),
"Afficher le chrono": ("Show timer", "Timer tonen", "Mostrar cronómetro", "显示计时器"),
"Afficher les erreurs": ("Show mistakes", "Fouten tonen", "Mostrar erros", "显示错误"),
"Aides": ("Assists", "Hulpmiddelen", "Ajudas", "辅助"),
"Annuler": ("Undo", "Ongedaan", "Anular", "撤销"),
"Apparence": ("Appearance", "Weergave", "Aparência", "外观"),
"Au-delà des techniques classiques": ("Beyond classic techniques", "Voorbij de klassieke technieken", "Além das técnicas clássicas", "超越经典技巧"),
"Aucun score pour l'instant. Sois le premier !": ("No scores yet. Be the first!", "Nog geen scores. Wees de eerste!", "Ainda sem pontuações. Sê o primeiro!", "暂无成绩，快来争第一！"),
"Aucune technique classique ne s'applique ici. Regarde ce bloc.": ("No classic technique applies here. Look at this box.", "Hier werkt geen klassieke techniek. Kijk naar dit blok.", "Nenhuma técnica clássica se aplica aqui. Olha para este bloco.", "这里没有可用的经典技巧。看看这个宫。"),
"Battre %1$@ · 💡%2$lld": ("Beat %1$@ · 💡%2$lld", "Versla %1$@ · 💡%2$lld", "Bater %1$@ · 💡%2$lld", "超越 %1$@ · 💡%2$lld"),
"Bravo !": ("Well done!", "Goed gedaan!", "Muito bem!", "太棒了！"),
"Bravo, la flamme est entretenue aujourd'hui.": ("Well done, your flame is lit for today.", "Goed zo, je vlam brandt vandaag.", "Muito bem, a chama está acesa hoje.", "很好，今天的火焰已点燃。"),
"Ce chiffre ne correspond pas à la solution.": ("This number doesn't match the solution.", "Dit cijfer klopt niet met de oplossing.", "Este número não corresponde à solução.", "这个数字与答案不符。"),
"Cette case est la plus contrainte de la grille.": ("This is the most constrained cell in the grid.", "Dit is het meest beperkte vakje van het rooster.", "Esta é a casa mais restrita da grelha.", "这是盘面中限制最多的格子。"),
"Cette case n'a plus qu'une possibilité.": ("This cell has only one possibility left.", "Dit vakje heeft nog maar één mogelijkheid.", "Esta casa só tem uma possibilidade.", "这个格子只剩一种可能。"),
"Change la langue de Sudokuno sans modifier celle de ton iPhone.": ("Changes Sudokuno's language without changing your iPhone's.", "Wijzigt de taal van Sudokuno zonder die van je iPhone te veranderen.", "Muda o idioma do Sudokuno sem alterar o do teu iPhone.", "仅更改 Sudokuno 的语言，不影响 iPhone 的语言。"),
"Clair": ("Light", "Licht", "Claro", "浅色"),
"Classement": ("Leaderboard", "Ranglijst", "Classificação", "排行榜"),
"Classement indisponible pour le moment.": ("Leaderboard unavailable right now.", "Ranglijst momenteel niet beschikbaar.", "Classificação indisponível de momento.", "排行榜暂时不可用。"),
"Classements": ("Leaderboards", "Ranglijsten", "Classificações", "排行榜"),
"Classements Game Center": ("Game Center leaderboards", "Game Center-ranglijsten", "Classificações do Game Center", "Game Center 排行榜"),
"Code": ("Code", "Code", "Código", "代码"),
"Code : %@": ("Code: %@", "Code: %@", "Código: %@", "代码：%@"),
"Code copié": ("Code copied", "Code gekopieerd", "Código copiado", "代码已复制"),
"Code de la grille": ("Puzzle code", "Puzzelcode", "Código da grelha", "谜题代码"),
"Code invalide. Vérifie qu'il commence par SKN1.": ("Invalid code. Check that it starts with SKN1.", "Ongeldige code. Controleer of hij met SKN1 begint.", "Código inválido. Verifica se começa por SKN1.", "代码无效。请确认以 SKN1 开头。"),
"Colle le message reçu ou tape le code. On retrouve exactement la même grille, et le défi s'il y en a un.": ("Paste the message you received or type the code. You'll get the exact same puzzle, plus the challenge if there is one.", "Plak het ontvangen bericht of typ de code. Je krijgt precies dezelfde puzzel, en de uitdaging als die er is.", "Cola a mensagem recebida ou escreve o código. Obténs exatamente a mesma grelha, e o desafio se houver.", "粘贴收到的消息或输入代码，即可获得完全相同的谜题（如有挑战也会一并载入）。"),
"Connecte-toi à Game Center (Réglages › Game Center) pour voir les classements.": ("Sign in to Game Center (Settings › Game Center) to see leaderboards.", "Log in bij Game Center (Instellingen › Game Center) om de ranglijsten te zien.", "Inicia sessão no Game Center (Definições › Game Center) para ver as classificações.", "登录 Game Center（设置 › Game Center）即可查看排行榜。"),
"Connecté": ("Signed in", "Ingelogd", "Ligado", "已登录"),
"Continuer": ("Continue", "Doorgaan", "Continuar", "继续"),
"Copier le code %@": ("Copy code %@", "Code %@ kopiëren", "Copiar código %@", "复制代码 %@"),
"Coup difficile": ("Tough move", "Lastige zet", "Jogada difícil", "难点"),
"Dans %@, un des chiffres manquants ne peut aller que dans cette case. Lequel ?": ("In %@, one of the missing numbers can only go in this cell. Which one?", "In %@ kan één van de ontbrekende cijfers alleen in dit vakje. Welk?", "Em %@, um dos números em falta só pode ir para esta casa. Qual?", "在%@中，有一个缺少的数字只能填在这个格子里。是哪个？"),
"Dans cette case, un seul chiffre est encore possible. Lequel ?": ("Only one number is still possible in this cell. Which one?", "In dit vakje is nog maar één cijfer mogelijk. Welk?", "Nesta casa, só um número ainda é possível. Qual?", "这个格子只剩一个可能的数字。是哪个？"),
"Diabolique": ("Diabolical", "Duivels", "Diabólico", "地狱"),
"Difficile": ("Hard", "Moeilijk", "Difícil", "困难"),
"Du jour": ("Daily", "Dagelijks", "Do dia", "每日"),
"Du jour · %@": ("Daily · %@", "Dagelijks · %@", "Do dia · %@", "每日 · %@"),
"Du jour, sans indice": ("Daily, no hints", "Dagelijks, zonder hints", "Do dia, sem dicas", "每日（无提示）"),
"Défi": ("Challenge", "Uitdaging", "Desafio", "挑战"),
"Défi %@": ("%@ challenge", "Uitdaging %@", "Desafio %@", "%@挑战"),
"Défi Sudokuno": ("Sudokuno challenge", "Sudokuno-uitdaging", "Desafio Sudokuno", "Sudokuno 挑战"),
"Défi raté de %@. Retente ta chance !": ("Missed by %@. Try again!", "Net niet: %@ te langzaam. Probeer het opnieuw!", "Falhaste por %@. Tenta outra vez!", "差了 %@，再试一次！"),
"Défi réussi : %@ plus rapide !": ("Challenge won: %@ faster!", "Uitdaging gewonnen: %@ sneller!", "Desafio ganho: %@ mais rápido!", "挑战成功：快了 %@！"),
"Défi · %@": ("Challenge · %@", "Uitdaging · %@", "Desafio · %@", "挑战 · %@"),
"Défis gagnés": ("Challenges won", "Gewonnen uitdagingen", "Desafios ganhos", "赢得的挑战"),
"Effacer": ("Erase", "Wissen", "Apagar", "擦除"),
"Effacer l'erreur": ("Erase the mistake", "Fout wissen", "Apagar o erro", "擦除错误"),
"Effacer les notes automatiquement": ("Auto-remove notes", "Notities automatisch wissen", "Apagar notas automaticamente", "自动清除笔记"),
"Entrer un code": ("Enter a code", "Code invoeren", "Introduzir código", "输入代码"),
"Erreurs": ("Mistakes", "Fouten", "Erros", "错误"),
"Essaie cette grille Sudokuno (%@) !": ("Try this Sudokuno puzzle (%@)!", "Probeer deze Sudokuno-puzzel (%@)!", "Experimenta esta grelha Sudokuno (%@)!", "试试这道 Sudokuno 谜题（%@）！"),
"Expert": ("Expert", "Expert", "Especialista", "专家"),
"Facile": ("Easy", "Makkelijk", "Fácil", "简单"),
"Fais le Sudoku du jour pour la prolonger !": ("Play the Daily Sudoku to keep it going!", "Speel de Sudoku van de dag om hem te verlengen!", "Faz o Sudoku do dia para a prolongar!", "完成今日数独来延续连胜！"),
"Fermer": ("Close", "Sluiten", "Fechar", "关闭"),
"Fermer l'indice": ("Close hint", "Hint sluiten", "Fechar dica", "关闭提示"),
"Game Center": ("Game Center", "Game Center", "Game Center", "Game Center"),
"Gels": ("Freezes", "Bevriezingen", "Congelamentos", "冻结"),
"Grille %@ terminée": ("%@ puzzle completed", "%@-puzzel voltooid", "Grelha %@ concluída", "%@谜题已完成"),
"Grille d'un jour passé réussie": ("Past daily puzzle completed", "Puzzel van een eerdere dag voltooid", "Grelha de um dia anterior concluída", "已完成往日谜题"),
"Grille partagée terminée": ("Shared puzzle completed", "Gedeelde puzzel voltooid", "Grelha partilhada concluída", "分享的谜题已完成"),
"Grille partagée · %@": ("Shared puzzle · %@", "Gedeelde puzzel · %@", "Grelha partilhada · %@", "分享的谜题 · %@"),
"Grille trouvée": ("Puzzle found", "Puzzel gevonden", "Grelha encontrada", "已找到谜题"),
"Grilles du jour": ("Daily puzzles", "Dagpuzzels", "Grelhas do dia", "每日谜题"),
"Grilles réussies": ("Puzzles completed", "Voltooide puzzels", "Grelhas concluídas", "完成的谜题"),
"Heure": ("Time", "Tijd", "Hora", "时间"),
"Il y a une erreur": ("There's a mistake", "Er zit een fout in", "Há um erro", "有一个错误"),
"Indice": ("Hint", "Hint", "Dica", "提示"),
"Indices": ("Hints", "Hints", "Dicas", "提示"),
"Indices (3 par grille)": ("Hints (3 per puzzle)", "Hints (3 per puzzel)", "Dicas (3 por grelha)", "提示（每题 3 次）"),
"Jalons": ("Milestones", "Mijlpalen", "Marcos", "里程碑"),
"Jeu": ("Game", "Spel", "Jogo", "游戏"),
"Jouer": ("Play", "Spelen", "Jogar", "开始"),
"Lance ta série": ("Start your streak", "Start je reeks", "Começa a tua série", "开启连胜"),
"Lance une nouvelle grille": ("Starts a new puzzle", "Start een nieuwe puzzel", "Começa uma nova grelha", "开始新谜题"),
"Langue": ("Language", "Taal", "Idioma", "语言"),
"Langue de l'appareil": ("Device language", "Taal van het apparaat", "Idioma do dispositivo", "跟随设备"),
"Le Sudoku du jour est prêt. Lance ta série 🔥": ("The Daily Sudoku is ready. Start your streak 🔥", "De Sudoku van de dag staat klaar. Start je reeks 🔥", "O Sudoku do dia está pronto. Começa a tua série 🔥", "今日数独已就绪，开启你的连胜 🔥"),
"Le nombre d'indices utilisés apparaît à la fin de la partie, dans les messages partagés et dans les classements Game Center. Le réglage s'applique aux nouvelles parties.": ("The number of hints used appears at the end of the game, in shared messages and in Game Center leaderboards. The setting applies to new games.", "Het aantal gebruikte hints verschijnt aan het einde van de partij, in gedeelde berichten en in de Game Center-ranglijsten. De instelling geldt voor nieuwe partijen.", "O número de dicas usadas aparece no fim do jogo, nas mensagens partilhadas e nas classificações do Game Center. A definição aplica-se aos novos jogos.", "使用的提示次数会显示在游戏结束时、分享的消息以及 Game Center 排行榜中。此设置对新游戏生效。"),
"Ligne %1$lld, colonne %2$lld": ("Row %1$lld, column %2$lld", "Rij %1$lld, kolom %2$lld", "Linha %1$lld, coluna %2$lld", "第 %1$lld 行，第 %2$lld 列"),
"Meilleur temps": ("Best time", "Beste tijd", "Melhor tempo", "最佳时间"),
"Montrer la case": ("Show the cell", "Toon het vakje", "Mostrar a casa", "显示格子"),
"Moyen": ("Medium", "Gemiddeld", "Médio", "中等"),
"Niveau": ("Level", "Niveau", "Nível", "难度"),
"Niveau %@ débloqué !": ("%@ level unlocked!", "Niveau %@ ontgrendeld!", "Nível %@ desbloqueado!", "已解锁%@难度！"),
"Niveau verrouillé": ("Level locked", "Niveau vergrendeld", "Nível bloqueado", "难度未解锁"),
"Niveaux": ("Levels", "Niveaus", "Níveis", "难度"),
"Non connecté. Connecte-toi dans Réglages › Game Center pour apparaître dans les classements.": ("Not signed in. Sign in under Settings › Game Center to appear on leaderboards.", "Niet ingelogd. Log in via Instellingen › Game Center om in de ranglijsten te verschijnen.", "Sessão não iniciada. Inicia sessão em Definições › Game Center para aparecer nas classificações.", "未登录。在 设置 › Game Center 中登录即可上榜。"),
"Note %lld": ("Note %lld", "Notitie %lld", "Nota %lld", "笔记 %lld"),
"Notes": ("Notes", "Notities", "Notas", "笔记"),
"Notes : oui": ("Notes: on", "Notities: aan", "Notas: sim", "笔记：开"),
"Notifications": ("Notifications", "Meldingen", "Notificações", "通知"),
"Nouveau record ! (avant : %@)": ("New record! (previous: %@)", "Nieuw record! (vorige: %@)", "Novo recorde! (antes: %@)", "新纪录！（之前：%@）"),
"Nouvelle grille %@": ("New %@ puzzle", "Nieuwe puzzel %@", "Nova grelha %@", "新的%@谜题"),
"OK": ("OK", "OK", "OK", "好"),
"Ouvrir Game Center": ("Open Game Center", "Game Center openen", "Abrir Game Center", "打开 Game Center"),
"Paire cachée": ("Hidden pair", "Verborgen paar", "Par escondido", "隐性数对"),
"Paire nue": ("Naked pair", "Naakt paar", "Par nu", "显性数对"),
"Paires et interactions bloc-ligne": ("Pairs and box-line interactions", "Paren en blok-lijninteracties", "Pares e interações bloco-linha", "数对与宫行列交互"),
"Parfait !": ("Perfect!", "Perfect!", "Perfeito!", "完美！"),
"Parfaites (0 indice, 0 erreur)": ("Perfect (0 hints, 0 mistakes)", "Perfect (0 hints, 0 fouten)", "Perfeitas (0 dicas, 0 erros)", "完美（0 提示，0 错误）"),
"Partager cette grille": ("Share this puzzle", "Deze puzzel delen", "Partilhar esta grelha", "分享此谜题"),
"Partager mon temps": ("Share my time", "Mijn tijd delen", "Partilhar o meu tempo", "分享我的成绩"),
"Parties commencées": ("Games started", "Gestarte partijen", "Jogos iniciados", "已开始的游戏"),
"Pense d'abord à éliminer des candidats (%@).": ("First, eliminate some candidates (%@).", "Elimineer eerst wat kandidaten (%@).", "Primeiro, elimina alguns candidatos (%@).", "先排除一些候选数（%@）。"),
"Plus d'options": ("More options", "Meer opties", "Mais opções", "更多选项"),
"Plus longue série": ("Longest streak", "Langste reeks", "Série mais longa", "最长连胜"),
"Pointage": ("Pointing", "Wijzende kandidaten", "Apontamento", "区块摒除"),
"Politique de confidentialité": ("Privacy policy", "Privacybeleid", "Política de privacidade", "隐私政策"),
"Prochaine grille dans %1$lld h %2$02lld": ("Next puzzle in %1$lldh %2$02lld", "Volgende puzzel over %1$lld u %2$02lld", "Próxima grelha dentro de %1$lld h %2$02lld", "下一题还有 %1$lld 小时 %2$02lld 分"),
"Préparation de la grille…": ("Preparing the puzzle…", "Puzzel wordt voorbereid…", "A preparar a grelha…", "正在准备谜题…"),
"Rappel de série": ("Streak reminder", "Reeksherinnering", "Lembrete da série", "连胜提醒"),
"Record": ("Best", "Record", "Recorde", "纪录"),
"Record %@": ("%@ record", "Record %@", "Recorde %@", "%@纪录"),
"Regarde %@.": ("Look at %@.", "Kijk naar %@.", "Olha para %@.", "看看%@。"),
"Relever le défi": ("Take the challenge", "Uitdaging aangaan", "Aceitar o desafio", "接受挑战"),
"Remis à zéro chaque jour à minuit UTC, avec la grille du jour.": ("Resets every day at midnight UTC, with the daily puzzle.", "Wordt elke dag om middernacht UTC gereset, samen met de dagpuzzel.", "Reinicia todos os dias à meia-noite UTC, com a grelha do dia.", "每天 UTC 午夜随每日谜题一起重置。"),
"Reprendre · %@": ("Resume · %@", "Hervatten · %@", "Retomar · %@", "继续 · %@"),
"Reviens demain pour la prolonger.": ("Come back tomorrow to keep it going.", "Kom morgen terug om hem te verlengen.", "Volta amanhã para a prolongar.", "明天再来延续连胜。"),
"Réduction bloc-ligne": ("Box/line reduction", "Blok-lijnreductie", "Redução bloco-linha", "行列区块摒除"),
"Réglages": ("Settings", "Instellingen", "Definições", "设置"),
"Réinitialiser": ("Reset", "Herstellen", "Repor", "重置"),
"Réinitialiser les statistiques": ("Reset statistics", "Statistieken herstellen", "Repor estatísticas", "重置统计"),
"Réussi en %@": ("Solved in %@", "Opgelost in %@", "Resolvido em %@", "用时 %@ 完成"),
"Réussis le Sudoku du jour pour allumer la flamme.": ("Solve the Daily Sudoku to light the flame.", "Los de Sudoku van de dag op om de vlam aan te steken.", "Resolve o Sudoku do dia para acender a chama.", "完成今日数独，点燃火焰。"),
"Révéler le chiffre": ("Reveal the number", "Cijfer onthullen", "Revelar o número", "显示数字"),
"Sans aide": ("No assists", "Zonder hulp", "Sem ajuda", "无辅助"),
"Sans indice": ("No hints", "Zonder hints", "Sem dicas", "无提示"),
"Singleton caché": ("Hidden single", "Verborgen single", "Único escondido", "隐性唯一"),
"Singleton nu": ("Naked single", "Naakte single", "Único nu", "唯一候选数"),
"Singletons : idéal pour démarrer": ("Singles: perfect to get started", "Singles: ideaal om te beginnen", "Únicos: ideal para começar", "唯一数：适合入门"),
"Sombre": ("Dark", "Donker", "Escuro", "深色"),
"Statistiques": ("Statistics", "Statistieken", "Estatísticas", "统计"),
"Succès": ("Achievements", "Prestaties", "Conquistas", "成就"),
"Sudoku du jour": ("Daily Sudoku", "Sudoku van de dag", "Sudoku do dia", "每日数独"),
"Sudoku du jour réussi": ("Daily Sudoku solved", "Sudoku van de dag opgelost", "Sudoku do dia resolvido", "每日数独已完成"),
"Sudoku du jour · %@": ("Daily Sudoku · %@", "Sudoku van de dag · %@", "Sudoku do dia · %@", "每日数独 · %@"),
"Sudokuno": ("Sudokuno", "Sudokuno", "Sudokuno", "Sudokuno"),
"Sudokuno est gratuit, sans publicité et sans suivi. Les seuls achats sont des dons facultatifs. Tes données restent sur ton appareil.": ("Sudokuno is free, ad-free and tracking-free. The only purchases are optional tips. Your data stays on your device.", "Sudokuno is gratis, zonder advertenties en zonder tracking. De enige aankopen zijn vrijwillige fooien. Je gegevens blijven op je apparaat.", "O Sudokuno é gratuito, sem publicidade e sem rastreio. As únicas compras são donativos opcionais. Os teus dados ficam no teu dispositivo.", "Sudokuno 免费、无广告、无追踪。唯一的购买项目是自愿打赏。你的数据只保存在设备上。"),
"Surligner les chiffres identiques": ("Highlight identical numbers", "Gelijke cijfers markeren", "Destacar números iguais", "高亮相同数字"),
"Surligner les conflits": ("Highlight conflicts", "Conflicten markeren", "Destacar conflitos", "高亮冲突"),
"Surligner ligne, colonne et bloc": ("Highlight row, column and box", "Rij, kolom en blok markeren", "Destacar linha, coluna e bloco", "高亮行、列和宫"),
"Système": ("System", "Systeem", "Sistema", "系统"),
"Série": ("Streak", "Reeks", "Série", "连胜"),
"Série actuelle": ("Current streak", "Huidige reeks", "Série atual", "当前连胜"),
"Série en cours": ("Current streak", "Huidige reeks", "Série atual", "当前连胜"),
"Série, statistiques, niveaux débloqués et parties en cours seront effacés.": ("Streak, statistics, unlocked levels and games in progress will be erased.", "Reeks, statistieken, ontgrendelde niveaus en lopende partijen worden gewist.", "A série, as estatísticas, os níveis desbloqueados e os jogos em curso serão apagados.", "连胜、统计、已解锁难度和进行中的游戏都将被清除。"),
"Ta grille en cours sera perdue.": ("Your current puzzle will be lost.", "Je huidige puzzel gaat verloren.", "A tua grelha atual será perdida.", "当前谜题的进度将会丢失。"),
"Taux de réussite": ("Success rate", "Slagingspercentage", "Taxa de sucesso", "完成率"),
"Temps": ("Time", "Tijd", "Tempo", "时间"),
"Temps moyen": ("Average time", "Gemiddelde tijd", "Tempo médio", "平均时间"),
"Thème": ("Theme", "Thema", "Tema", "主题"),
"Touche un jour passé pour rejouer sa grille (sans effet sur la série).": ("Tap a past day to replay its puzzle (doesn't affect your streak).", "Tik op een eerdere dag om die puzzel opnieuw te spelen (telt niet mee voor je reeks).", "Toca num dia anterior para voltar a jogar a grelha (sem efeito na série).", "点击过去的日期可重玩当天谜题（不影响连胜）。"),
"Tout réinitialiser ?": ("Reset everything?", "Alles herstellen?", "Repor tudo?", "全部重置？"),
"Triplet caché": ("Hidden triple", "Verborgen drietal", "Trio escondido", "隐性三数组"),
"Triplet nu": ("Naked triple", "Naakt drietal", "Trio nu", "显性三数组"),
"Triplets et X-Wing": ("Triples and X-Wing", "Drietallen en X-Wing", "Trios e X-Wing", "三数组与 X-Wing"),
"Un des chiffres de ce bloc est faux.": ("One of the numbers in this box is wrong.", "Eén van de cijfers in dit blok is fout.", "Um dos números deste bloco está errado.", "这个宫里有一个数字是错的。"),
"Une notification locale si le Sudoku du jour n'est pas encore fait. Rien n'est envoyé sur Internet.": ("A local notification if the Daily Sudoku isn't done yet. Nothing is sent over the internet.", "Een lokale melding als de Sudoku van de dag nog niet gedaan is. Er wordt niets via internet verstuurd.", "Uma notificação local se o Sudoku do dia ainda não estiver feito. Nada é enviado pela Internet.", "若今日数独尚未完成，将发送本地通知。不会通过互联网发送任何数据。"),
"Version": ("Version", "Versie", "Versão", "版本"),
"Vibrations": ("Haptics", "Trillingen", "Vibração", "振动"),
"Victoires": ("Wins", "Overwinningen", "Vitórias", "胜利"),
"Voir mes succès": ("View my achievements", "Mijn prestaties bekijken", "Ver as minhas conquistas", "查看我的成就"),
"cette zone": ("this area", "dit gebied", "esta zona", "这个区域"),
"erreur": ("mistake", "fout", "erro", "错误"),
"erreurs": ("mistakes", "fouten", "erros", "错误"),
"indices": ("hints", "hints", "dicas", "提示"),
"la colonne %lld": ("column %lld", "kolom %lld", "a coluna %lld", "第 %lld 列"),
"la ligne %lld": ("row %lld", "rij %lld", "a linha %lld", "第 %lld 行"),
"le bloc %lld": ("box %lld", "blok %lld", "o bloco %lld", "第 %lld 宫"),
"notes %@": ("notes %@", "notities %@", "notas %@", "笔记 %@"),
"record": ("best", "record", "recorde", "纪录"),
"temps": ("time", "tijd", "tempo", "时间"),
"vide": ("empty", "leeg", "vazia", "空"),
"À propos": ("About", "Over", "Sobre", "关于"),
"À toi de battre mon temps ! Code : %@": ("Can you beat my time? Code: %@", "Kun jij mijn tijd verslaan? Code: %@", "Consegues bater o meu tempo? Código: %@", "你能打破我的纪录吗？代码：%@"),
"💡 sans indice": ("💡 no hints", "💡 zonder hints", "💡 sem dicas", "💡 无提示"),
"🚫 sans aide": ("🚫 no assists", "🚫 zonder hulp", "🚫 sem ajuda", "🚫 无辅助"),
# --- Niveau Légende et chaînes ---
"Légende": ("Legend", "Legende", "Lenda", "传奇"),
"Légende · %@": ("Legend · %@", "Legende · %@", "Lenda · %@", "传奇 · %@"),
"Les grilles les plus dures du monde": ("The hardest puzzles in the world", "De moeilijkste puzzels ter wereld", "Os puzzles mais difíceis do mundo", "世界上最难的数独"),
"Chaînes : X-Chain, XY-Chain, AIC": ("Chains: X-Chain, XY-Chain, AIC", "Ketens: X-Chain, XY-Chain, AIC", "Cadeias: X-Chain, XY-Chain, AIC", "链：X-Chain、XY-Chain、AIC"),
"Chaîne d'inférences (AIC)": ("Alternating inference chain (AIC)", "Alternerende inferentieketen (AIC)", "Cadeia de inferências alternadas (AIC)", "交替推理链（AIC）"),
"Ces grilles sont célèbres dans le monde entier pour leur difficulté. Aucune technique de Sudokuno n'en vient à bout : il faudra de très longues chaînes de raisonnement, ou des essais.": (
    "These puzzles are famous around the world for their difficulty. None of Sudokuno's techniques can crack them: you will need very long chains of reasoning, or trial and error.",
    "Deze puzzels zijn wereldberoemd om hun moeilijkheid. Geen enkele techniek van Sudokuno kraakt ze: je hebt heel lange redeneerketens nodig, of moet gokken.",
    "Estes puzzles são famosos no mundo inteiro pela sua dificuldade. Nenhuma técnica do Sudokuno os resolve: vais precisar de cadeias de raciocínio muito longas, ou de tentativas.",
    "这些数独以难度闻名于世。Sudokuno 的任何技巧都无法解开它们：你需要非常长的推理链，或者反复尝试。"),
"Forums de passionnés": ("Enthusiast forums", "Fansforums", "Fóruns de entusiastas", "爱好者论坛"),
"Pas encore résolue": ("Not solved yet", "Nog niet opgelost", "Ainda não resolvido", "尚未解开"),
"Résolue · record %@": ("Solved · best %@", "Opgelost · record %@", "Resolvido · recorde %@", "已解开 · 最佳 %@"),
"Lance la grille": ("Starts the puzzle", "Start de puzzel", "Inicia o puzzle", "开始这个数独"),
"Publiée en 2006 par le mathématicien finlandais Arto Inkala, qui la présentait comme la grille la plus difficile du monde.": (
    "Published in 2006 by Finnish mathematician Arto Inkala, who presented it as the hardest sudoku in the world.",
    "In 2006 gepubliceerd door de Finse wiskundige Arto Inkala, die hem presenteerde als de moeilijkste sudoku ter wereld.",
    "Publicado em 2006 pelo matemático finlandês Arto Inkala, que o apresentou como o sudoku mais difícil do mundo.",
    "2006 年由芬兰数学家 Arto Inkala 发布，他称其为世界上最难的数独。"),
"Arto Inkala dit avoir mis trois mois à créer cette grille, encore plus dure qu'AI Escargot.": (
    "Arto Inkala says he spent three months creating this puzzle, even harder than AI Escargot.",
    "Arto Inkala zegt dat hij drie maanden aan deze puzzel werkte, die nog moeilijker is dan AI Escargot.",
    "Arto Inkala diz ter levado três meses a criar este puzzle, ainda mais difícil do que o AI Escargot.",
    "Arto Inkala 说他花了三个月创作这道题，比 AI Escargot 还要难。"),
"La « grille la plus difficile du monde » qui a fait le tour de la presse en juin 2012.": (
    "The \"world's hardest sudoku\" that made headlines around the world in June 2012.",
    "De \"moeilijkste sudoku ter wereld\" die in juni 2012 wereldwijd het nieuws haalde.",
    "O \"sudoku mais difícil do mundo\" que fez manchetes em junho de 2012.",
    "2012 年 6 月登上各大媒体的“世界最难数独”。"),
"Célèbre chez les spécialistes pour son motif presque symétrique en croix : l'une des grilles les plus dures connues.": (
    "Famous among experts for its almost symmetrical cross pattern: one of the hardest puzzles known.",
    "Bij kenners beroemd om zijn bijna symmetrische kruispatroon: een van de moeilijkste bekende puzzels.",
    "Famoso entre especialistas pelo seu padrão em cruz quase simétrico: um dos puzzles mais difíceis conhecidos.",
    "因近乎对称的十字图案而在高手中闻名：已知最难的数独之一。"),
"Longtemps en tête des classements de difficulté établis par les passionnés.": (
    "Long at the top of the difficulty rankings kept by enthusiasts.",
    "Stond lang bovenaan de moeilijkheidsranglijsten van liefhebbers.",
    "Esteve muito tempo no topo das classificações de dificuldade feitas pelos entusiastas.",
    "长期位居爱好者难度排行榜榜首。"),
"Jugée la plus difficile par les chercheurs Ercsey-Ravasz et Toroczkai, qui mesurent la difficulté comme du chaos.": (
    "Rated the hardest by researchers Ercsey-Ravasz and Toroczkai, who measure difficulty as chaos.",
    "Volgens onderzoekers Ercsey-Ravasz en Toroczkai, die moeilijkheid als chaos meten, de allermoeilijkste.",
    "Considerado o mais difícil pelos investigadores Ercsey-Ravasz e Toroczkai, que medem a dificuldade como caos.",
    "研究者 Ercsey-Ravasz 和 Toroczkai 以混沌度衡量难度，认为它是最难的。"),
"Une des grilles « insolubles » de SudokuWiki : aucune technique logique classique n'en vient à bout.": (
    "One of SudokuWiki's \"unsolvable\" puzzles: no classic logical technique can crack it.",
    "Een van de \"onoplosbare\" puzzels van SudokuWiki: geen klassieke logische techniek kraakt hem.",
    "Um dos puzzles \"insolúveis\" do SudokuWiki: nenhuma técnica lógica clássica o resolve.",
    "SudokuWiki 的“无解”数独之一：任何经典逻辑技巧都无法解开。"),
"Connexion à Google Play Jeux impossible pour le moment. Réessaie plus tard.": (
    "Couldn't sign in to Google Play Games right now. Please try again later.",
    "Inloggen bij Google Play Games lukt nu niet. Probeer het later opnieuw.",
    "Não foi possível iniciar sessão no Google Play Jogos. Tenta mais tarde.",
    "暂时无法登录 Google Play 游戏，请稍后再试。"),
# --- Mes grilles ---
"Mes grilles": ("My puzzles", "Mijn puzzels", "Os meus puzzles", "我的数独"),
"Créées": ("Created", "Gemaakt", "Criados", "我创建的"),
"Reçues": ("Received", "Ontvangen", "Recebidos", "收到的"),
"Aucune grille créée. Crée la tienne avec l'éditeur !": ("No puzzles created yet. Make your own with the editor!", "Nog geen puzzels gemaakt. Maak je eigen puzzel met de editor!", "Ainda não criaste puzzles. Cria o teu com o editor!", "还没有创建数独。用编辑器创建你自己的吧！"),
"Les grilles reçues par lien ou par code apparaîtront ici.": ("Puzzles you receive by link or code will appear here.", "Puzzels die je via een link of code ontvangt, verschijnen hier.", "Os puzzles recebidos por link ou código aparecerão aqui.", "通过链接或代码收到的数独会显示在这里。"),
"Pas encore jouée": ("Not played yet", "Nog niet gespeeld", "Ainda não jogado", "尚未开始"),
"Résolue · %@": ("Solved · %@", "Opgelost · %@", "Resolvido · %@", "已解开 · %@"),
"Terminé": ("Done", "Klaar", "Concluído", "完成"),
"Grille enregistrée": ("Puzzle saved", "Puzzel opgeslagen", "Puzzle guardado", "数独已保存"),
"Tu la retrouves dans Mes grilles. Tu peux en créer une nouvelle.": ("You'll find it in My puzzles. You can create a new one.", "Je vindt hem terug in Mijn puzzels. Je kunt een nieuwe maken.", "Encontra-lo em Os meus puzzles. Podes criar um novo.", "你可以在“我的数独”中找到它。现在可以创建新的了。"),
}

# Pluriels : clé -> {langue: (un, autre)}. Le français (source) est inclus pour « 1 jour » / « 2 jours ».
P = {
"%lld jours de série": {
    "fr": ("%lld jour de série", "%lld jours de série"),
    "en": ("%lld day streak", "%lld day streak"),
    "nl": ("%lld dag reeks", "%lld dagen reeks"),
    "pt-PT": ("%lld dia de série", "%lld dias de série"),
    "zh-Hans": (None, "连胜 %lld 天")},
"%lld gels de série": {
    "fr": ("%lld gel de série", "%lld gels de série"),
    "en": ("%lld streak freeze", "%lld streak freezes"),
    "nl": ("%lld reeksbevriezing", "%lld reeksbevriezingen"),
    "pt-PT": ("%lld congelamento de série", "%lld congelamentos de série"),
    "zh-Hans": (None, "%lld 次连胜冻结")},
"%lld erreurs": {
    "fr": ("%lld erreur", "%lld erreurs"),
    "en": ("%lld mistake", "%lld mistakes"),
    "nl": ("%lld fout", "%lld fouten"),
    "pt-PT": ("%lld erro", "%lld erros"),
    "zh-Hans": (None, "%lld 个错误")},
"Jalon atteint : %lld jours 🎉": {
    "fr": ("Jalon atteint : %lld jour 🎉", "Jalon atteint : %lld jours 🎉"),
    "en": ("Milestone reached: %lld day 🎉", "Milestone reached: %lld days 🎉"),
    "nl": ("Mijlpaal bereikt: %lld dag 🎉", "Mijlpaal bereikt: %lld dagen 🎉"),
    "pt-PT": ("Marco alcançado: %lld dia 🎉", "Marco alcançado: %lld dias 🎉"),
    "zh-Hans": (None, "达成里程碑：%lld 天 🎉")},
"%lld jours, atteint": {
    "fr": ("%lld jour, atteint", "%lld jours, atteint"),
    "en": ("%lld day, reached", "%lld days, reached"),
    "nl": ("%lld dag, bereikt", "%lld dagen, bereikt"),
    "pt-PT": ("%lld dia, alcançado", "%lld dias, alcançado"),
    "zh-Hans": (None, "%lld 天，已达成")},
"%lld jours, pas encore atteint": {
    "fr": ("%lld jour, pas encore atteint", "%lld jours, pas encore atteint"),
    "en": ("%lld day, not reached yet", "%lld days, not reached yet"),
    "nl": ("%lld dag, nog niet bereikt", "%lld dagen, nog niet bereikt"),
    "pt-PT": ("%lld dia, ainda não alcançado", "%lld dias, ainda não alcançado"),
    "zh-Hans": (None, "%lld 天，尚未达成")},
"Ta série de %lld jours t'attend 🔥 Le Sudoku du jour est prêt.": {
    "fr": ("Ta série de %lld jour t'attend 🔥 Le Sudoku du jour est prêt.", "Ta série de %lld jours t'attend 🔥 Le Sudoku du jour est prêt."),
    "en": ("Your %lld-day streak is waiting 🔥 The Daily Sudoku is ready.", "Your %lld-day streak is waiting 🔥 The Daily Sudoku is ready."),
    "nl": ("Je reeks van %lld dag wacht op je 🔥 De Sudoku van de dag staat klaar.", "Je reeks van %lld dagen wacht op je 🔥 De Sudoku van de dag staat klaar."),
    "pt-PT": ("A tua série de %lld dia está à tua espera 🔥 O Sudoku do dia está pronto.", "A tua série de %lld dias está à tua espera 🔥 O Sudoku do dia está pronto."),
    "zh-Hans": (None, "你的 %lld 天连胜在等你 🔥 今日数独已就绪。")},
"💡 %lld indices": {
    "fr": ("💡 %lld indice", "💡 %lld indices"),
    "en": ("💡 %lld hint", "💡 %lld hints"),
    "nl": ("💡 %lld hint", "💡 %lld hints"),
    "pt-PT": ("💡 %lld dica", "💡 %lld dicas"),
    "zh-Hans": (None, "💡 %lld 次提示")},
"Tu gagnes un gel tous les %1$lld jours de série (%2$lld au maximum). Un gel protège ta série si tu oublies un jour.": {
    "en": (None, "You earn a freeze every %1$lld days of streak (%2$lld max). A freeze protects your streak if you miss a day."),
    "nl": (None, "Je verdient een bevriezing per %1$lld dagen reeks (maximaal %2$lld). Een bevriezing beschermt je reeks als je een dag mist."),
    "pt-PT": (None, "Ganhas um congelamento a cada %1$lld dias de série (%2$lld no máximo). Um congelamento protege a tua série se falhares um dia."),
    "zh-Hans": (None, "每连胜 %1$lld 天可获得一次冻结（最多 %2$lld 次）。忘记一天时，冻结可以保护你的连胜。")},
}

# Phrases dont la forme française source est maladroite au singulier : on fournit une valeur française explicite.
FR_OVERRIDE = {
"%1$lld indices utilisés sur %2$lld": "Indices utilisés : %1$lld sur %2$lld",
}
T["%1$lld indices utilisés sur %2$lld"] = ("%1$lld of %2$lld hints used", "%1$lld van %2$lld hints gebruikt", "%1$lld de %2$lld dicas usadas", "已用提示 %1$lld/%2$lld")

# --- Créateur, historique, soutien ---
T.update({
"Ajouter un chiffre suggéré": ("Add a suggested number", "Voorgesteld cijfer toevoegen", "Adicionar um número sugerido", "添加建议数字"),
"Analyse": ("Analysis", "Analyse", "Análise", "分析"),
"Aucune partie en cours.": ("No games in progress.", "Geen lopende partijen.", "Nenhum jogo em curso.", "没有进行中的游戏。"),
"Aucune solution : cette grille est impossible. Retire ou change un chiffre.": ("No solution: this puzzle is impossible. Remove or change a number.", "Geen oplossing: deze puzzel is onmogelijk. Verwijder of wijzig een cijfer.", "Sem solução: esta grelha é impossível. Retira ou muda um número.", "无解：此谜题无法完成。请删除或修改一个数字。"),
"Cette grille n'a pas de solution unique.": ("This puzzle doesn't have a unique solution.", "Deze puzzel heeft geen unieke oplossing.", "Esta grelha não tem solução única.", "此谜题没有唯一解。"),
"Code de ta grille": ("Your puzzle code", "Code van je puzzel", "Código da tua grelha", "你的谜题代码"),
"Conflit : un chiffre apparaît deux fois dans une ligne, une colonne ou un bloc.": ("Conflict: a number appears twice in a row, column or box.", "Conflict: een cijfer staat twee keer in een rij, kolom of blok.", "Conflito: um número aparece duas vezes numa linha, coluna ou bloco.", "冲突：某个数字在同一行、列或宫中出现了两次。"),
"Copier": ("Copy", "Kopiëren", "Copiar", "复制"),
"Créer une grille": ("Create a puzzle", "Puzzel maken", "Criar uma grelha", "创建谜题"),
"Demande des techniques au-delà des classiques.": ("Requires techniques beyond the classics.", "Vereist technieken voorbij de klassiekers.", "Exige técnicas além das clássicas.", "需要超越经典的技巧。"),
"Effacer toute la grille ?": ("Clear the whole puzzle?", "Hele puzzel wissen?", "Apagar a grelha toda?", "清空整个谜题？"),
"En cours": ("In progress", "Bezig", "Em curso", "进行中"),
"Glisse vers la gauche pour supprimer une partie.": ("Swipe left to delete a game.", "Veeg naar links om een partij te verwijderen.", "Desliza para a esquerda para apagar um jogo.", "向左滑动可删除游戏。"),
"Grille créée par un joueur": ("Player-made puzzle", "Door speler gemaakte puzzel", "Grelha criada por um jogador", "玩家自制谜题"),
"Grille créée · %@": ("Custom puzzle · %@", "Eigen puzzel · %@", "Grelha criada · %@", "自制谜题 · %@"),
"Grille valide : solution unique": ("Valid puzzle: unique solution", "Geldige puzzel: unieke oplossing", "Grelha válida: solução única", "有效谜题：唯一解"),
"Historique": ("History", "Geschiedenis", "Histórico", "历史"),
"Il faut au moins 17 chiffres pour qu'une grille ait une solution unique.": ("A puzzle needs at least 17 numbers to have a unique solution.", "Een puzzel heeft minstens 17 cijfers nodig voor een unieke oplossing.", "Uma grelha precisa de pelo menos 17 números para ter solução única.", "谜题至少需要 17 个数字才可能有唯一解。"),
"Jouer cette grille": ("Play this puzzle", "Deze puzzel spelen", "Jogar esta grelha", "玩这道谜题"),
"Le code contient toute ta grille : tes amis retrouvent exactement la même, même hors ligne.": ("The code contains your whole puzzle: your friends get exactly the same one, even offline.", "De code bevat je hele puzzel: je vrienden krijgen precies dezelfde, zelfs offline.", "O código contém a grelha inteira: os teus amigos obtêm exatamente a mesma, mesmo offline.", "代码包含整道谜题：朋友即使离线也能获得完全相同的谜题。"),
"Les grilles que tu termines apparaîtront ici.": ("Puzzles you complete will appear here.", "Puzzels die je voltooit verschijnen hier.", "As grelhas que concluíres aparecem aqui.", "你完成的谜题会显示在这里。"),
"Offre-moi un café": ("Buy me a coffee", "Trakteer me op een koffie", "Paga-me um café", "请我喝杯咖啡"),
"Partager": ("Share", "Delen", "Partilhar", "分享"),
"Pas encore assez de chiffres pour conclure. Continue à remplir.": ("Not enough numbers to tell yet. Keep filling in.", "Nog niet genoeg cijfers om het te bepalen. Vul verder in.", "Ainda não há números suficientes para concluir. Continua a preencher.", "数字还不够，无法判断。请继续填写。"),
"Plusieurs solutions possibles : ajoute des chiffres pour qu'il n'y en ait qu'une.": ("Several solutions possible: add numbers so there's only one.", "Meerdere oplossingen mogelijk: voeg cijfers toe zodat er maar één is.", "Várias soluções possíveis: adiciona números para que só haja uma.", "存在多个解：请添加数字，使答案唯一。"),
"Rejouer": ("Replay", "Opnieuw spelen", "Jogar de novo", "重玩"),
"Soutenir Sudokuno": ("Support Sudokuno", "Sudokuno steunen", "Apoiar o Sudokuno", "支持 Sudokuno"),
"Sudokuno est gratuit et sans publicité. Si tu l'aimes, tu peux soutenir son développement sur Ko-fi.": ("Sudokuno is free and ad-free. If you enjoy it, you can support its development on Ko-fi.", "Sudokuno is gratis en zonder advertenties. Vind je het leuk, steun dan de ontwikkeling via Ko-fi.", "O Sudokuno é gratuito e sem publicidade. Se gostas, podes apoiar o desenvolvimento no Ko-fi.", "Sudokuno 免费且无广告。如果你喜欢，可以在 Ko-fi 上支持开发。"),
"Supprimer": ("Delete", "Verwijderen", "Apagar", "删除"),
"Technique la plus difficile : %@": ("Hardest technique: %@", "Moeilijkste techniek: %@", "Técnica mais difícil: %@", "最难技巧：%@"),
"Terminées": ("Completed", "Voltooid", "Concluídas", "已完成"),
"Tout effacer": ("Clear all", "Alles wissen", "Apagar tudo", "全部清除"),
})
P.update({
"%lld chiffres": {
    "fr": ("%lld chiffre", "%lld chiffres"),
    "en": ("%lld number", "%lld numbers"),
    "nl": ("%lld cijfer", "%lld cijfers"),
    "pt-PT": ("%lld número", "%lld números"),
    "zh-Hans": (None, "%lld 个数字")},
"+ %lld autres parties en cours": {
    "fr": ("+ %lld autre partie en cours", "+ %lld autres parties en cours"),
    "en": ("+ %lld other game in progress", "+ %lld other games in progress"),
    "nl": ("+ %lld andere lopende partij", "+ %lld andere lopende partijen"),
    "pt-PT": ("+ %lld outro jogo em curso", "+ %lld outros jogos em curso"),
    "zh-Hans": (None, "+ 另有 %lld 局进行中")},
})

# --- Pot à pourboires ---
T.update({
"Petit café": ("Small coffee", "Kleine koffie", "Café pequeno", "小杯咖啡"),
"Grand café": ("Large coffee", "Grote koffie", "Café grande", "大杯咖啡"),
"Café et croissant": ("Coffee & croissant", "Koffie met croissant", "Café e croissant", "咖啡加可颂"),
"Dons indisponibles pour le moment.": ("Tips unavailable right now.", "Fooien zijn momenteel niet beschikbaar.", "Donativos indisponíveis de momento.", "打赏暂时不可用。"),
"Sudokuno est gratuit et sans publicité. Un don facultatif aide à financer son développement, il ne débloque rien. Merci !": ("Sudokuno is free and ad-free. An optional tip helps fund its development and doesn't unlock anything. Thank you!", "Sudokuno is gratis en zonder advertenties. Een vrijwillige fooi helpt de ontwikkeling te financieren en ontgrendelt niets. Bedankt!", "O Sudokuno é gratuito e sem publicidade. Um donativo opcional ajuda a financiar o desenvolvimento e não desbloqueia nada. Obrigado!", "Sudokuno 免费且无广告。自愿打赏用于支持开发，不会解锁任何内容。谢谢！"),
"Merci ! 💜": ("Thank you! 💜", "Bedankt! 💜", "Obrigado! 💜", "谢谢！💜"),
"Paiement en attente": ("Payment pending", "Betaling in behandeling", "Pagamento pendente", "付款待处理"),
"Don non effectué": ("Tip not completed", "Fooi niet voltooid", "Donativo não concluído", "打赏未完成"),
"Ton soutien compte beaucoup pour Sudokuno.": ("Your support means a lot to Sudokuno.", "Je steun betekent veel voor Sudokuno.", "O teu apoio significa muito para o Sudokuno.", "你的支持对 Sudokuno 意义重大。"),
"Le paiement doit encore être validé. Merci de ta patience !": ("The payment still needs to be approved. Thanks for your patience!", "De betaling moet nog worden goedgekeurd. Bedankt voor je geduld!", "O pagamento ainda tem de ser aprovado. Obrigado pela paciência!", "付款仍需确认，感谢你的耐心！"),
"L'achat n'a pas pu aboutir. Aucun montant n'a été débité.": ("The purchase couldn't be completed. You haven't been charged.", "De aankoop kon niet worden voltooid. Er is niets afgeschreven.", "A compra não foi concluída. Não foi cobrado nenhum valor.", "购买未能完成，未扣除任何费用。"),
})
P.update({
"Tu as fait %lld dons. Merci ! 💜": {
    "fr": ("Tu as fait %lld don. Merci ! 💜", "Tu as fait %lld dons. Merci ! 💜"),
    "en": ("You've tipped %lld time. Thank you! 💜", "You've tipped %lld times. Thank you! 💜"),
    "nl": ("Je hebt %lld keer een fooi gegeven. Bedankt! 💜", "Je hebt %lld keer een fooi gegeven. Bedankt! 💜"),
    "pt-PT": ("Fizeste %lld donativo. Obrigado! 💜", "Fizeste %lld donativos. Obrigado! 💜"),
    "zh-Hans": (None, "你已打赏 %lld 次，谢谢！💜")},
})

# --- Montant libre ---
T.update({
"Montant libre": ("Custom amount", "Eigen bedrag", "Valor livre", "自定义金额"),
"Offrir": ("Give", "Geven", "Oferecer", "打赏"),
"Choisis combien de cafés offrir, jusqu'à %lld en une fois.": ("Choose how many coffees to give, up to %lld at once.", "Kies hoeveel koffie je wilt geven, tot %lld in één keer.", "Escolhe quantos cafés queres oferecer, até %lld de uma vez.", "选择要请几杯咖啡，一次最多 %lld 杯。"),
})
P.update({
"%lld cafés": {
    "fr": ("%lld café", "%lld cafés"),
    "en": ("%lld coffee", "%lld coffees"),
    "nl": ("%lld koffie", "%lld koffies"),
    "pt-PT": ("%lld café", "%lld cafés"),
    "zh-Hans": (None, "%lld 杯咖啡")},
})

T.update({
"Aide et contact": ("Help & contact", "Hulp en contact", "Ajuda e contacto", "帮助与联系"),
"Mentions légales": ("Legal notice", "Juridische informatie", "Informações legais", "法律声明"),
})

# --- Abandon ---
T.update({
"Abandonner la partie": ("Give up this game", "Partij opgeven", "Desistir do jogo", "放弃本局"),
"Abandonner cette partie ?": ("Give up this game?", "Deze partij opgeven?", "Desistir deste jogo?", "放弃这局游戏？"),
"Abandonner": ("Give up", "Opgeven", "Desistir", "放弃"),
"Elle sera rangée dans l'historique avec les parties terminées. Tu pourras la reprendre à tout moment.": ("It will be moved to your history with finished games. You can resume it at any time.", "Hij wordt bij de voltooide partijen in je geschiedenis gezet. Je kunt hem op elk moment hervatten.", "Será guardado no histórico com os jogos terminados. Podes retomá-lo a qualquer momento.", "它将与已完成的游戏一起放入历史记录，你可以随时继续。"),
"Abandonnée": ("Given up", "Opgegeven", "Abandonado", "已放弃"),
"Reprendre": ("Resume", "Hervatten", "Retomar", "继续"),
"Touche une partie abandonnée pour la reprendre où tu l'avais laissée.": ("Tap a game you gave up to pick it up where you left off.", "Tik op een opgegeven partij om verder te gaan waar je was gebleven.", "Toca num jogo abandonado para o retomar onde o deixaste.", "点击已放弃的游戏，可从上次中断处继续。"),
})

# --- Android ---
T.update({
"Google Play Jeux": ("Google Play Games", "Google Play Games", "Google Play Jogos", "Google Play 游戏"),
"Ouvrir Google Play Jeux": ("Open Google Play Games", "Google Play Games openen", "Abrir Google Play Jogos", "打开 Google Play 游戏"),
"Connecte-toi à Google Play Jeux pour voir les classements.": ("Sign in to Google Play Games to see leaderboards.", "Log in bij Google Play Games om de ranglijsten te zien.", "Inicia sessão no Google Play Jogos para ver as classificações.", "登录 Google Play 游戏即可查看排行榜。"),
"Change la langue de Sudokuno sans modifier celle de ton téléphone.": ("Changes Sudokuno's language without changing your phone's.", "Wijzigt de taal van Sudokuno zonder die van je telefoon te veranderen.", "Muda o idioma do Sudokuno sem alterar o do teu telemóvel.", "仅更改 Sudokuno 的语言，不影响手机的语言。"),
"Le nombre d'indices utilisés apparaît à la fin de la partie, dans les messages partagés et dans les classements Google Play Jeux. Le réglage s'applique aux nouvelles parties.": ("The number of hints used appears at the end of the game, in shared messages and in Google Play Games leaderboards. The setting applies to new games.", "Het aantal gebruikte hints verschijnt aan het einde van de partij, in gedeelde berichten en in de Google Play Games-ranglijsten. De instelling geldt voor nieuwe partijen.", "O número de dicas usadas aparece no fim do jogo, nas mensagens partilhadas e nas classificações do Google Play Jogos. A definição aplica-se aos novos jogos.", "使用的提示次数会显示在游戏结束时、分享的消息以及 Google Play 游戏排行榜中。此设置对新游戏生效。"),
"Coller": ("Paste", "Plakken", "Colar", "粘贴"),
})

LANGS = ["en", "nl", "pt-PT", "zh-Hans"]

def unit(v):
    return {"stringUnit": {"state": "translated", "value": v}}

def scan(folder, pattern):
    keys = set()
    for f in glob.glob(os.path.join(folder, "**", pattern), recursive=True):
        for m in re.finditer(r'\bL\("((?:[^"\\]|\\.)*)"', open(f, encoding="utf-8").read()):
            keys.add(m.group(1).replace('\\$', '$'))
    return keys

def to_java(fmt):
    """Formats Apple (%@, %lld, %1$@, %2$02lld) → formats Java (%s, %d, %1$s, %2$02d)."""
    fmt = re.sub(r'%(\d+\$)?(0?\d*)lld', lambda m: '%' + (m.group(1) or '') + m.group(2) + 'd', fmt)
    fmt = re.sub(r'%(\d+\$)?@', lambda m: '%' + (m.group(1) or '') + 's', fmt)
    return fmt

def check(keys, where):
    missing = sorted(k for k in keys if k not in T and k not in P)
    if missing:
        print(f"Clés sans traduction ({where}) :", *missing, sep="\n  ")
        sys.exit(1)

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ios_app = os.path.join(root, "ios", "Sudokuno")
    android_src = os.path.join(root, "android", "app", "src", "main", "java")
    swift_keys = scan(ios_app, "*.swift")
    kotlin_keys = scan(android_src, "*.kt")
    check(swift_keys, "iOS")
    check(kotlin_keys, "Android")

    # --- iOS : String Catalog ---
    strings = {}
    for key in sorted(swift_keys):
        loc = {}
        if key in FR_OVERRIDE:
            loc["fr"] = unit(FR_OVERRIDE[key])
        if key in P:
            for lang, (one, other) in P[key].items():
                forms = {"other": unit(other)}
                if one is not None:
                    forms["one"] = unit(one)
                loc[lang] = {"variations": {"plural": forms}}
        if key in T:
            for lang, value in zip(LANGS, T[key]):
                loc.setdefault(lang, unit(value))
        strings[key] = {"extractionState": "manual", "localizations": loc}
    catalog = {"sourceLanguage": "fr", "strings": strings, "version": "1.0"}
    out = os.path.join(ios_app, "Localizable.xcstrings")
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(catalog, fh, ensure_ascii=False, indent=2, sort_keys=True)
    print(f"iOS : {len(strings)} chaînes → {os.path.relpath(out, root)}")

    # --- Android : assets/i18n.json (clé = texte français, format Java) ---
    langs = ["fr"] + LANGS
    table = {lang: {} for lang in langs}
    for key in sorted(kotlin_keys):
        jkey = to_java(key)
        for lang in langs:
            if key in P and lang in P[key]:
                one, other = P[key][lang]
                forms = {"other": to_java(other)}
                if one is not None:
                    forms["one"] = to_java(one)
                table[lang][jkey] = forms
            elif lang == "fr":
                if key in FR_OVERRIDE:
                    table[lang][jkey] = to_java(FR_OVERRIDE[key])
            elif key in T:
                table[lang][jkey] = to_java(T[key][LANGS.index(lang)])
    out = os.path.join(root, "android", "app", "src", "main", "assets", "i18n.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(table, fh, ensure_ascii=False, indent=1, sort_keys=True)
    print(f"Android : {len(kotlin_keys)} chaînes → {os.path.relpath(out, root)}")

main()
