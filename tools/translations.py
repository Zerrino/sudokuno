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

# --- Explication pas à pas, aides du créateur ---
T.update({
"L%1$@C%2$@": ("R%1$@C%2$@", "R%1$@K%2$@", "L%1$@C%2$@", "R%1$@C%2$@"),
"la ligne %@": ("row %@", "rij %@", "a linha %@", "第 %@ 行"),
"la colonne %@": ("column %@", "kolom %@", "a coluna %@", "第 %@ 列"),
"le bloc %@": ("box %@", "blok %@", "o bloco %@", "第 %@ 宫"),
"les lignes %@": ("rows %@", "rijen %@", "as linhas %@", "第 %@ 行"),
"les colonnes %@": ("columns %@", "kolommen %@", "as colunas %@", "第 %@ 列"),
"Aucune des techniques de Sudokuno ne permet d'avancer ici : cette grille demande des méthodes encore plus avancées. On pose le %1$@ en %2$@, tiré de la solution, pour continuer.": (
    "None of Sudokuno's techniques makes progress here: this puzzle needs even more advanced methods. We place %1$@ in %2$@, taken from the solution, to carry on.",
    "Geen van de technieken van Sudokuno helpt hier verder: deze puzzel vraagt nog geavanceerdere methodes. We plaatsen de %1$@ in %2$@, uit de oplossing, om verder te gaan.",
    "Nenhuma das técnicas do Sudokuno permite avançar aqui: esta grelha exige métodos ainda mais avançados. Colocamos o %1$@ em %2$@, retirado da solução, para continuar.",
    "Sudokuno 的技巧在这里都无法推进：这道题需要更高级的方法。我们从答案中取出 %1$@ 填入 %2$@，以便继续。"),
"La case %1$@ n'a plus qu'un candidat : le %2$@. Tous les autres chiffres sont déjà dans sa ligne, sa colonne ou son bloc.": (
    "Cell %1$@ has only one candidate left: %2$@. Every other number is already in its row, column or box.",
    "Vakje %1$@ heeft nog maar één kandidaat: de %2$@. Alle andere cijfers staan al in zijn rij, kolom of blok.",
    "A casa %1$@ só tem um candidato: o %2$@. Todos os outros números já estão na sua linha, coluna ou bloco.",
    "格子 %1$@ 只剩一个候选数：%2$@。其他数字都已出现在它所在的行、列或宫中。"),
"Dans %1$@, le %2$@ ne peut aller qu'en %3$@ : il est exclu de toutes les autres cases.": (
    "In %1$@, %2$@ can only go in %3$@: it is ruled out of every other cell.",
    "In %1$@ kan de %2$@ alleen in %3$@: in alle andere vakjes is hij uitgesloten.",
    "Em %1$@, o %2$@ só pode ir em %3$@: está excluído de todas as outras casas.",
    "在%1$@中，%2$@ 只能填在 %3$@：其他格子都已排除。"),
"Dans %1$@, toutes les places possibles du %2$@ se trouvent aussi dans %3$@. Le %2$@ occupera donc l'une d'elles : on le retire des autres cases dans %3$@.": (
    "In %1$@, every possible place for %2$@ also lies in %3$@. So %2$@ will take one of them: remove it from the other cells in %3$@.",
    "In %1$@ liggen alle mogelijke plaatsen voor de %2$@ ook in %3$@. De %2$@ komt dus op een daarvan: verwijder hem uit de andere vakjes in %3$@.",
    "Em %1$@, todos os lugares possíveis do %2$@ ficam também em %3$@. O %2$@ ocupará portanto um deles: retira-se das outras casas em %3$@.",
    "在%1$@中，%2$@ 所有可能的位置同时也在%3$@中。因此 %2$@ 必定占据其中一格：把它从%3$@的其他格子中删除。"),
"Dans %1$@, les cases %2$@ ne contiennent ensemble que les candidats %3$@. Ces chiffres leur sont réservés : on les retire des autres cases dans %1$@.": (
    "In %1$@, cells %2$@ together hold only the candidates %3$@. Those numbers are reserved for them: remove them from the other cells in %1$@.",
    "In %1$@ bevatten de vakjes %2$@ samen alleen de kandidaten %3$@. Die cijfers zijn voor hen gereserveerd: verwijder ze uit de andere vakjes in %1$@.",
    "Em %1$@, as casas %2$@ contêm em conjunto apenas os candidatos %3$@. Esses números estão-lhes reservados: retiram-se das outras casas em %1$@.",
    "在%1$@中，格子 %2$@ 合起来只含候选数 %3$@。这些数字归它们所有：把它们从%1$@的其他格子中删除。"),
"Dans %1$@, les chiffres %2$@ ne peuvent aller que dans les cases %3$@. Ces cases leur sont réservées : on y retire tous les autres candidats.": (
    "In %1$@, the numbers %2$@ can only go in cells %3$@. Those cells are reserved for them: remove every other candidate from them.",
    "In %1$@ kunnen de cijfers %2$@ alleen in de vakjes %3$@. Die vakjes zijn voor hen gereserveerd: verwijder daar alle andere kandidaten.",
    "Em %1$@, os números %2$@ só podem ir nas casas %3$@. Essas casas estão-lhes reservadas: retiram-se delas todos os outros candidatos.",
    "在%1$@中，数字 %2$@ 只能填在格子 %3$@。这些格子归它们所有：删除其中所有其他候选数。"),
"Dans %2$@, le %1$@ n'a de place que dans %3$@. Il occupera forcément ces croisements : on le retire de toutes les autres cases dans %3$@.": (
    "In %2$@, %1$@ only fits in %3$@. It must take those crossings: remove it from every other cell in %3$@.",
    "In %2$@ past de %1$@ alleen in %3$@. Hij komt zeker op die kruispunten: verwijder hem uit alle andere vakjes in %3$@.",
    "Em %2$@, o %1$@ só tem lugar em %3$@. Ocupará forçosamente esses cruzamentos: retira-se de todas as outras casas em %3$@.",
    "在%2$@中，%1$@ 只能落在%3$@。它必定占据这些交叉点：把它从%3$@的其他格子中删除。"),
"Le pivot %1$@ n'a que deux candidats. Quel que soit le bon, l'une des deux ailes (%2$@) prendra le %3$@. Une case qui voit les deux ailes ne peut donc pas contenir le %3$@.": (
    "The pivot %1$@ has only two candidates. Whichever is right, one of the two wings (%2$@) will be %3$@. So a cell that sees both wings cannot hold %3$@.",
    "De spil %1$@ heeft maar twee kandidaten. Welke ook klopt, een van de twee vleugels (%2$@) wordt de %3$@. Een vakje dat beide vleugels ziet, kan dus geen %3$@ bevatten.",
    "O pivô %1$@ só tem dois candidatos. Seja qual for o certo, uma das duas asas (%2$@) ficará com o %3$@. Uma casa que vê as duas asas não pode portanto conter o %3$@.",
    "枢纽格 %1$@ 只有两个候选数。无论哪个正确，两个翼格（%2$@）之一必为 %3$@。因此同时看到两个翼格的格子不可能是 %3$@。"),
"Le pivot %1$@ et ses deux ailes (%2$@) contiennent tous le %3$@, et l'une de ces trois cases le prendra forcément. Une case qui voit les trois ne peut donc pas contenir le %3$@.": (
    "The pivot %1$@ and its two wings (%2$@) all hold %3$@, and one of these three cells must take it. So a cell that sees all three cannot hold %3$@.",
    "De spil %1$@ en zijn twee vleugels (%2$@) bevatten allemaal de %3$@, en een van deze drie vakjes krijgt hem zeker. Een vakje dat alle drie ziet, kan dus geen %3$@ bevatten.",
    "O pivô %1$@ e as suas duas asas (%2$@) contêm todos o %3$@, e uma destas três casas ficará forçosamente com ele. Uma casa que vê as três não pode portanto conter o %3$@.",
    "枢纽格 %1$@ 和它的两个翼格（%2$@）都含有 %3$@，三格之一必为 %3$@。因此同时看到这三格的格子不可能是 %3$@。"),
"Suis la chaîne : %@. Le signe = est un lien fort (si l'un est faux, l'autre est vrai) ; le signe – est un lien faible (si l'un est vrai, l'autre est faux). Si le premier maillon est faux, le dernier est vrai : l'un des deux bouts est donc forcément vrai, et tout candidat incompatible avec les deux est retiré.": (
    "Follow the chain: %@. The = sign is a strong link (if one is false, the other is true); the – sign is a weak link (if one is true, the other is false). If the first link is false, the last one is true: so one of the two ends must be true, and any candidate incompatible with both is removed.",
    "Volg de ketting: %@. Het teken = is een sterke schakel (als de ene onwaar is, is de andere waar); het teken – is een zwakke schakel (als de ene waar is, is de andere onwaar). Als de eerste schakel onwaar is, is de laatste waar: een van de twee uiteinden is dus zeker waar, en elke kandidaat die met beide botst, wordt verwijderd.",
    "Segue a cadeia: %@. O sinal = é uma ligação forte (se um é falso, o outro é verdadeiro); o sinal – é uma ligação fraca (se um é verdadeiro, o outro é falso). Se o primeiro elo é falso, o último é verdadeiro: uma das duas pontas é portanto forçosamente verdadeira, e qualquer candidato incompatível com ambas é retirado.",
    "沿着这条链：%@。符号 = 表示强链（一个为假，另一个必为真）；符号 – 表示弱链（一个为真，另一个必为假）。如果第一个节点为假，最后一个就为真：所以两端必有一个为真，与两端都冲突的候选数可以删除。"),
"On place le %1$@ en %2$@.": ("Place %1$@ in %2$@.", "Plaats de %1$@ in %2$@.", "Coloca-se o %1$@ em %2$@.", "在 %2$@ 填入 %1$@。"),
"Candidats retirés : %@.": ("Candidates removed: %@.", "Verwijderde kandidaten: %@.", "Candidatos retirados: %@.", "删除的候选数：%@。"),
"Explication pas à pas": ("Step-by-step explanation", "Uitleg stap voor stap", "Explicação passo a passo", "逐步讲解"),
"Cette grille n'a pas de solution unique : impossible de l'expliquer.": ("This puzzle has no unique solution: it can't be explained.", "Deze puzzel heeft geen unieke oplossing: uitleg is niet mogelijk.", "Esta grelha não tem solução única: não é possível explicá-la.", "这道题没有唯一解，无法讲解。"),
"Analyse de la grille…": ("Analysing the puzzle…", "Puzzel analyseren…", "A analisar a grelha…", "正在分析题目…"),
"Grille résolue": ("Puzzle solved", "Puzzel opgelost", "Grelha resolvida", "已解完"),
"Étape %1$@ sur %2$@": ("Step %1$@ of %2$@", "Stap %1$@ van %2$@", "Passo %1$@ de %2$@", "第 %1$@ 步，共 %2$@ 步"),
"Tu as vu toute la résolution, en %@ étapes.": ("You've seen the whole solve, in %@ steps.", "Je hebt de hele oplossing gezien, in %@ stappen.", "Viste toda a resolução, em %@ passos.", "你已看完整个解题过程，共 %@ 步。"),
"Précédent": ("Previous", "Vorige", "Anterior", "上一步"),
"Suivant": ("Next", "Volgende", "Seguinte", "下一步"),
"Étape clé suivante": ("Next key step", "Volgende sleutelstap", "Próximo passo-chave", "下一个关键步骤"),
"Revenir au début": ("Back to the start", "Terug naar het begin", "Voltar ao início", "回到开头"),
"Techniques utilisées": ("Techniques used", "Gebruikte technieken", "Técnicas usadas", "用到的技巧"),
"Voir la résolution expliquée": ("See the explained solution", "Bekijk de uitgelegde oplossing", "Ver a resolução explicada", "查看解题讲解"),
"Compléter automatiquement": ("Complete automatically", "Automatisch aanvullen", "Completar automaticamente", "自动补全"),
"Grille minimale : aucun chiffre en trop.": ("Minimal puzzle: no extra numbers.", "Minimale puzzel: geen overbodige cijfers.", "Grelha mínima: nenhum número a mais.", "最简题目：没有多余的数字。"),
"%@ chiffres peuvent être retirés sans changer la solution.": ("%@ numbers can be removed without changing the solution.", "%@ cijfers kunnen weg zonder de oplossing te veranderen.", "%@ números podem ser retirados sem alterar a solução.", "有 %@ 个数字可以删除而不改变答案。"),
"Voir": ("Show", "Tonen", "Ver", "查看"),
"Masquer": ("Hide", "Verbergen", "Ocultar", "隐藏"),
"Utilise au moins 8 chiffres différents : avec moins, il y a forcément plusieurs solutions.": ("Use at least 8 different numbers: with fewer, there are always several solutions.", "Gebruik minstens 8 verschillende cijfers: met minder zijn er altijd meerdere oplossingen.", "Usa pelo menos 8 números diferentes: com menos, há sempre várias soluções.", "至少使用 8 个不同的数字：少于 8 个必然有多个解。"),
"Seules les grilles parfaites sont classées : sans indice, sans erreur et du premier coup.": ("Only perfect puzzles are ranked: no hints, no mistakes, first attempt.", "Alleen perfecte puzzels tellen mee: zonder hints, zonder fouten en in één keer.", "Só as grelhas perfeitas são classificadas: sem dicas, sem erros e à primeira.", "只有完美通关才计入排行榜：无提示、无错误、一次完成。"),
"Chaîne forcée": ("Forcing chain", "Geforceerde ketting", "Cadeia forçada", "强制链"),
"Réseau forcé": ("Forcing net", "Geforceerd net", "Rede forçada", "强制网"),
"Les techniques classiques ne suffisent plus : on raisonne par l'absurde. Supposons que %1$@ contienne le %2$@. Voici ce que cela impose, coup après coup :": (
    "The classic techniques are no longer enough: we reason by contradiction. Suppose %1$@ holds %2$@. Here is what that forces, move after move:",
    "De klassieke technieken volstaan niet meer: we redeneren uit het ongerijmde. Stel dat %1$@ de %2$@ bevat. Dit volgt daar dan dwingend uit, zet na zet:",
    "As técnicas clássicas já não chegam: raciocinamos por absurdo. Suponhamos que %1$@ contém o %2$@. Eis o que isso obriga, jogada após jogada:",
    "经典技巧已经不够用：我们用反证法。假设 %1$@ 填 %2$@，那么必然依次得到："),
"%1$@ = %2$@ : c'est son seul candidat restant.": ("%1$@ = %2$@: it is its only remaining candidate.", "%1$@ = %2$@: dat is de enige overgebleven kandidaat.", "%1$@ = %2$@: é o único candidato que resta.", "%1$@ = %2$@：这是它唯一剩下的候选数。"),
"%1$@ = %2$@ : c'est la seule place du %2$@ dans %3$@.": ("%1$@ = %2$@: it is the only place for %2$@ in %3$@.", "%1$@ = %2$@: dat is de enige plaats voor de %2$@ in %3$@.", "%1$@ = %2$@: é o único lugar do %2$@ em %3$@.", "%1$@ = %2$@：这是%3$@中 %2$@ 唯一能填的位置。"),
"%1$@ ne peut pas contenir le %2$@. En effet, si c'était le cas :": ("%1$@ cannot hold %2$@. Indeed, if it did:", "%1$@ kan geen %2$@ bevatten. Want als dat zo was:", "%1$@ não pode conter o %2$@. De facto, se assim fosse:", "%1$@ 不可能是 %2$@。因为如果是的话："),
"%1$@ ne peut pas contenir le %2$@ : cela mènerait aussi à une contradiction (preuve imbriquée, %3$@ coups).": (
    "%1$@ cannot hold %2$@: that would also lead to a contradiction (nested proof, %3$@ moves).",
    "%1$@ kan geen %2$@ bevatten: ook dat zou tot een tegenspraak leiden (genest bewijs, %3$@ zetten).",
    "%1$@ não pode conter o %2$@: isso também levaria a uma contradição (prova encaixada, %3$@ jogadas).",
    "%1$@ 不可能是 %2$@：那同样会导致矛盾（嵌套证明，%3$@ 步）。"),
"Contradiction : %@ n'a plus aucun candidat.": ("Contradiction: %@ has no candidate left.", "Tegenspraak: %@ heeft geen enkele kandidaat meer.", "Contradição: %@ já não tem nenhum candidato.", "矛盾：%@ 已没有任何候选数。"),
"Contradiction : le %1$@ n'a plus aucune place dans %2$@.": ("Contradiction: %1$@ has no place left in %2$@.", "Tegenspraak: de %1$@ heeft geen plaats meer in %2$@.", "Contradição: o %1$@ já não tem lugar em %2$@.", "矛盾：%1$@ 在%2$@中已无处可填。"),
"L'hypothèse est donc fausse : %1$@ ne contient pas le %2$@.": ("So the assumption is false: %1$@ does not hold %2$@.", "De aanname is dus onjuist: %1$@ bevat geen %2$@.", "A hipótese é portanto falsa: %1$@ não contém o %2$@.", "所以假设不成立：%1$@ 不是 %2$@。"),
"Détailler les preuves imbriquées": ("Show nested proofs", "Geneste bewijzen tonen", "Detalhar as provas encaixadas", "展开嵌套证明"),
"Masquer les preuves imbriquées": ("Hide nested proofs", "Geneste bewijzen verbergen", "Ocultar as provas encaixadas", "收起嵌套证明"),
"Calcul de la suite…": ("Working out the next steps…", "De volgende stappen worden berekend…", "A calcular os passos seguintes…", "正在计算后续步骤…"),
"Revoir la partie": ("Review the game", "Partij terugkijken", "Rever o jogo", "回看对局"),
"Coup %1$@ sur %2$@": ("Move %1$@ of %2$@", "Zet %1$@ van %2$@", "Jogada %1$@ de %2$@", "第 %1$@ 手，共 %2$@ 手"),
"Début de la partie": ("Start of the game", "Begin van de partij", "Início do jogo", "对局开始"),
"Tu effaces la case %@.": ("You clear cell %@.", "Je wist vakje %@.", "Apagas a casa %@.", "你清空了格子 %@。"),
"Tu places le %1$@ en %2$@.": ("You place %1$@ in %2$@.", "Je plaatst de %1$@ in %2$@.", "Colocas o %1$@ em %2$@.", "你在 %2$@ 填入 %1$@。"),
"Tu places le %1$@ en %2$@ : ce n'est pas le bon chiffre.": ("You place %1$@ in %2$@: that is not the right number.", "Je plaatst de %1$@ in %2$@: dat is niet het juiste cijfer.", "Colocas o %1$@ em %2$@: não é o número certo.", "你在 %2$@ 填入 %1$@：这不是正确的数字。"),
"Indice : la case %@ est effacée.": ("Hint: cell %@ is cleared.", "Hint: vakje %@ wordt gewist.", "Dica: a casa %@ é apagada.", "提示：清空格子 %@。"),
"Indice : le %1$@ en %2$@.": ("Hint: %1$@ in %2$@.", "Hint: de %1$@ in %2$@.", "Dica: o %1$@ em %2$@.", "提示：在 %2$@ 填入 %1$@。"),
"Annulation : la case %@ redevient vide.": ("Undo: cell %@ is empty again.", "Ongedaan: vakje %@ is weer leeg.", "Anulação: a casa %@ volta a ficar vazia.", "撤销：格子 %@ 恢复为空。"),
"Annulation : la case %1$@ revient au %2$@.": ("Undo: cell %1$@ goes back to %2$@.", "Ongedaan: vakje %1$@ wordt weer %2$@.", "Anulação: a casa %1$@ volta ao %2$@.", "撤销：格子 %1$@ 恢复为 %2$@。"),
"Lecture": ("Play", "Afspelen", "Reproduzir", "播放"),
"Pause": ("Pause", "Pauze", "Pausa", "暂停"),
"Erreur suivante": ("Next mistake", "Volgende fout", "Erro seguinte", "下一个错误"),
"Comment le repérer": ("How to spot it", "Zo vind je het", "Como o encontrar", "如何发现"),
"Dérouler l'hypothèse sur la grille": ("Play the assumption out on the grid", "Speel de aanname uit op het rooster", "Desenrolar a hipótese na grelha", "在盘面上演示这个假设"),
"Revenir à la vue d'ensemble": ("Back to the overview", "Terug naar het overzicht", "Voltar à vista geral", "返回总览"),
"Choisis une case et compte les chiffres déjà présents dans sa ligne, sa colonne et son bloc. S'il n'en manque qu'un, c'est lui. C'est plus facile dans les zones déjà bien remplies.": (
    "Pick a cell and count the numbers already in its row, column and box. If only one is missing, that's it. It is easier in areas that are already well filled.",
    "Kies een vakje en tel de cijfers die al in zijn rij, kolom en blok staan. Ontbreekt er maar één, dan is dat het. Dat gaat makkelijker in goed gevulde zones.",
    "Escolhe uma casa e conta os números já presentes na sua linha, coluna e bloco. Se só faltar um, é esse. É mais fácil nas zonas já bem preenchidas.",
    "选一个格子，数一数它所在的行、列、宫里已有的数字。如果只缺一个，那就是它。在已经填得较满的区域更容易看出。"),
"Concentre-toi sur un chiffre et un bloc. Barre mentalement les lignes et les colonnes qui contiennent déjà ce chiffre : s'il ne reste qu'une case libre dans le bloc, elle est pour lui.": (
    "Focus on one number and one box. Mentally cross out the rows and columns that already contain that number: if only one free cell is left in the box, it belongs there.",
    "Richt je op één cijfer en één blok. Streep in gedachten de rijen en kolommen weg waar dat cijfer al staat: blijft er in het blok maar één vrij vakje over, dan hoort het daar.",
    "Concentra-te num número e num bloco. Risca mentalmente as linhas e colunas que já contêm esse número: se só sobrar uma casa livre no bloco, é para ele.",
    "盯住一个数字和一个宫。在脑中划掉已含该数字的行和列：如果宫里只剩一个空格，那就是它的位置。"),
"Dans un bloc, regarde où un chiffre peut encore aller. Si toutes ses places sont alignées, ce chiffre est réservé à cet alignement. Fais aussi le contrôle inverse : une ligne dont les places tiennent dans un seul bloc.": (
    "In a box, look where a number can still go. If all its places are in line, the number is reserved for that line. Also check the reverse: a line whose places all fit in one box.",
    "Kijk in een blok waar een cijfer nog kan staan. Liggen al die plaatsen op één lijn, dan is het cijfer voor die lijn gereserveerd. Controleer ook het omgekeerde: een lijn waarvan de plaatsen in één blok vallen.",
    "Num bloco, vê onde um número ainda pode ir. Se todos os lugares estiverem alinhados, o número fica reservado a esse alinhamento. Faz também a verificação inversa: uma linha cujos lugares cabem num só bloco.",
    "在一个宫里，看某个数字还能放在哪里。如果这些位置都在同一条线上，这个数字就被这条线占用。也要反过来检查：一行中某数字的位置是否都落在同一个宫内。"),
"Dans une ligne, une colonne ou un bloc, cherche des cases qui n'ont presque plus de candidats. Deux cases avec les deux mêmes candidats (ou trois cases qui s'en partagent trois) se réservent ces chiffres.": (
    "In a row, column or box, look for cells with very few candidates left. Two cells with the same two candidates (or three cells sharing three) reserve those numbers.",
    "Zoek in een rij, kolom of blok naar vakjes met nog maar weinig kandidaten. Twee vakjes met dezelfde twee kandidaten (of drie vakjes die er samen drie delen) reserveren die cijfers.",
    "Numa linha, coluna ou bloco, procura casas quase sem candidatos. Duas casas com os mesmos dois candidatos (ou três casas que partilham três) reservam esses números.",
    "在一行、一列或一个宫里，找候选数很少的格子。两个格子有相同的两个候选数（或三个格子共用三个），这些数字就被它们占用。"),
"Raisonne par chiffre plutôt que par case : dans une unité, cherche deux chiffres (ou trois) qui n'ont que les mêmes cases possibles. Ces cases cachent souvent d'autres candidats, qu'on peut alors effacer.": (
    "Think by number rather than by cell: in a unit, look for two numbers (or three) that only fit in the same cells. Those cells often hide other candidates, which can then be removed.",
    "Denk per cijfer in plaats van per vakje: zoek in een eenheid twee cijfers (of drie) die alleen in dezelfde vakjes passen. Die vakjes verbergen vaak andere kandidaten, die je dan kunt wegstrepen.",
    "Raciocina por número e não por casa: numa unidade, procura dois números (ou três) que só cabem nas mesmas casas. Essas casas escondem muitas vezes outros candidatos, que podem então ser apagados.",
    "按数字而不是按格子来想：在一个单元里，找只能放在相同几个格子里的两个（或三个）数字。这些格子里往往还藏着其他候选数，可以删掉。"),
"Ne regarde qu'un seul chiffre à la fois. Cherche des lignes où il n'a que deux places (ou trois), et vérifie si ces places tombent dans les mêmes colonnes. Pense aussi à inverser lignes et colonnes.": (
    "Look at a single number at a time. Find rows where it has only two places (or three), and check whether those places fall in the same columns. Remember to swap rows and columns too.",
    "Bekijk één cijfer tegelijk. Zoek rijen waar het maar twee plaatsen heeft (of drie) en kijk of die plaatsen in dezelfde kolommen vallen. Wissel ook rijen en kolommen om.",
    "Olha para um só número de cada vez. Procura linhas onde ele só tem dois lugares (ou três) e verifica se esses lugares caem nas mesmas colunas. Lembra-te também de trocar linhas e colunas.",
    "一次只看一个数字。找出它只有两个（或三个）位置的行，检查这些位置是否落在相同的列上。也别忘了把行和列对调再找。"),
"Repère les cases à deux candidats. Prends-en une comme pivot et cherche deux cases qu'elle voit, chacune partageant un chiffre différent avec elle et ayant le même autre chiffre.": (
    "Spot the cells with two candidates. Take one as the pivot and look for two cells it sees, each sharing a different number with it and both having the same other number.",
    "Zoek de vakjes met twee kandidaten. Neem er één als spil en zoek twee vakjes die het ziet, die elk een ander cijfer met de spil delen en hetzelfde andere cijfer hebben.",
    "Identifica as casas com dois candidatos. Toma uma como pivô e procura duas casas que ela vê, cada uma partilhando um número diferente com ela e tendo o mesmo outro número.",
    "先找出只有两个候选数的格子。选一个作枢纽，再找它能看到的两个格子：各与它共有一个不同的数字，并且另一个数字相同。"),
"Pars d'un « soit l'un, soit l'autre » : un chiffre qui n'a que deux places dans une unité, ou une case à deux candidats. Suis ces liens de proche en proche, en alternant. Quand les deux bouts visent un même candidat, il tombe.": (
    "Start from an “either this or that”: a number with only two places in a unit, or a cell with two candidates. Follow these links step by step, alternating. When both ends point at the same candidate, it goes.",
    "Begin bij een ‘het ene of het andere’: een cijfer met maar twee plaatsen in een eenheid, of een vakje met twee kandidaten. Volg die schakels stap voor stap, om en om. Wijzen beide uiteinden naar dezelfde kandidaat, dan valt die weg.",
    "Parte de um «ou um, ou outro»: um número com apenas dois lugares numa unidade, ou uma casa com dois candidatos. Segue essas ligações passo a passo, alternando. Quando as duas pontas apontam para o mesmo candidato, ele cai.",
    "从“非此即彼”出发：某数字在一个单元里只有两个位置，或某格只有两个候选数。沿着这些链一步步交替推下去。当两端同时指向同一个候选数时，它就可以删掉。"),
"C'est l'outil de dernier recours des experts, quand aucun motif ne se voit. Choisis un candidat dans une case très contrainte et déroule ses conséquences obligatoires, au crayon. Si tu arrives à une impossibilité, le candidat de départ est faux.": (
    "This is the experts' last-resort tool, when no pattern shows. Pick a candidate in a very constrained cell and work out its forced consequences in pencil. If you reach an impossibility, the starting candidate is false.",
    "Dit is het laatste redmiddel van experts, als er geen patroon te zien is. Kies een kandidaat in een sterk beperkt vakje en werk met potlood de gedwongen gevolgen uit. Kom je op iets onmogelijks uit, dan is de beginkandidaat onjuist.",
    "É a ferramenta de último recurso dos especialistas, quando não se vê nenhum padrão. Escolhe um candidato numa casa muito restrita e desenrola as suas consequências obrigatórias, a lápis. Se chegares a uma impossibilidade, o candidato de partida é falso.",
    "这是高手在看不出任何模式时的最后手段。在限制很多的格子里选一个候选数，用铅笔推演它必然带来的后果。如果推出不可能的局面，起始候选数就是错的。"),
"Chaîne groupée": ("Grouped chain", "Gegroepeerde ketting", "Cadeia agrupada", "分组链"),
"Les quatre cases %1$@ forment un rectangle sur quatre blocs. Autour d'elles, les %2$@ cases vides voisines forment une boucle fermée, et elles ne peuvent contenir que %2$@ chiffres en tout, répartis ainsi : %3$@. Il y a exactement autant de chiffres que de cases : chaque lien de la boucle prend donc tous les siens, et on les retire des autres cases de sa ligne, de sa colonne ou de son bloc.": (
    "The four cells %1$@ form a rectangle across four boxes. Around them, the %2$@ neighbouring empty cells form a closed loop, and they can only hold %2$@ numbers in total, split as follows: %3$@. There are exactly as many numbers as cells: so each link of the loop takes all of its own, and they are removed from the other cells of its row, column or box.",
    "De vier vakjes %1$@ vormen een rechthoek over vier blokken. Daaromheen vormen de %2$@ aangrenzende lege vakjes een gesloten lus, en ze kunnen samen maar %2$@ cijfers bevatten, als volgt verdeeld: %3$@. Er zijn precies evenveel cijfers als vakjes: elke schakel van de lus neemt dus al zijn cijfers, en die verdwijnen uit de andere vakjes van zijn rij, kolom of blok.",
    "As quatro casas %1$@ formam um retângulo sobre quatro blocos. À volta delas, as %2$@ casas vazias vizinhas formam um anel fechado, e só podem conter %2$@ números no total, repartidos assim: %3$@. Há exatamente tantos números como casas: cada elo do anel fica portanto com todos os seus, e retiram-se das outras casas da sua linha, coluna ou bloco.",
    "四个格子 %1$@ 在四个宫上构成一个矩形。它们周围相邻的 %2$@ 个空格形成一个闭合的环，总共只能容纳 %2$@ 个数字，分配如下：%3$@。数字与格子的数量正好相等：因此环上每一段都必须占用它的全部数字，可以把这些数字从所在行、列或宫的其他格子中删除。"),
"Dans cette chaîne, une parenthèse désigne un groupe de cases alignées dans un même bloc : le chiffre est dans l'une d'elles.": (
    "In this chain, brackets mark a group of aligned cells in the same box: the number is in one of them.",
    "In deze ketting staan haakjes voor een groep vakjes op één lijn in hetzelfde blok: het cijfer staat in een daarvan.",
    "Nesta cadeia, os parênteses indicam um grupo de casas alinhadas no mesmo bloco: o número está numa delas.",
    "在这条链中，括号表示同一宫内排成一线的一组格子：该数字在其中某一格。"),
"Sur une grille qui résiste à tout, cherche quatre chiffres déjà posés qui forment un rectangle sur quatre blocs. Regarde les deux voisines de chacun sur sa ligne et sur sa colonne, à l'intérieur de son bloc : si ces seize cases se partagent peu de chiffres, compte-les.": (
    "On a puzzle that resists everything, look for four placed numbers that form a rectangle across four boxes. Look at each one's two neighbours along its row and its column, inside its box: if those sixteen cells share few numbers, count them.",
    "Zoek bij een puzzel die overal tegen bestand is naar vier geplaatste cijfers die een rechthoek over vier blokken vormen. Bekijk van elk de twee buren op zijn rij en zijn kolom, binnen zijn blok: delen die zestien vakjes maar weinig cijfers, tel ze dan.",
    "Numa grelha que resiste a tudo, procura quatro números já colocados que formem um retângulo sobre quatro blocos. Olha para os dois vizinhos de cada um na sua linha e na sua coluna, dentro do seu bloco: se essas dezasseis casas partilharem poucos números, conta-os.",
    "遇到什么方法都不管用的题目时，找四个已填数字，看它们是否在四个宫上构成矩形。再看每个数字在本宫内同一行、同一列的两个邻格：如果这十六个格子共用的数字很少，就数一数。"),
"Motif symétrique, comme les grilles des créateurs.": ("Symmetric pattern, like hand-crafted puzzles.", "Symmetrisch patroon, zoals bij ontworpen puzzels.", "Padrão simétrico, como nas grelhas de autor.", "对称图案，就像出题人设计的题目。"),
})

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
