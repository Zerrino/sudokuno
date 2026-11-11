package com.alexafer.sudokuno.kit

/**
 * Une grille célèbre pour sa difficulté. Elle se joue telle quelle et se partage avec un code de grille créée
 * (`PuzzleCode.Custom`) : le jeu la reconnaît à ses chiffres. Traduction de Legends.swift (même liste, même ordre).
 */
data class LegendPuzzle(
    /** Identifiant stable (sauvegardes, traductions). Ne jamais changer. */
    val id: String,
    /** Nom sous lequel la grille est connue (non traduit). */
    val name: String,
    /** Auteur, s'il est connu avec certitude. */
    val author: String?,
    val year: Int?,
    val givens: Grid,
)

object Legends {
    val all: List<LegendPuzzle> = listOf(
        make("escargot", "AI Escargot", "Arto Inkala", 2006,
            "100007090030020008009600500005300900010080002600004000300000010040000007007000300"),
        make("inkala2010", "Inkala 2010", "Arto Inkala", 2010,
            "005300000800000020070010500400005300010070006003200080060500009004000030000009700"),
        make("inkala2012", "Inkala 2012", "Arto Inkala", 2012,
            "800000000003600000070090200050007000000045700000100030001000068008500010090000400"),
        make("easter-monster", "Easter Monster", null, null,
            "100000002090400050006000700050903000000070000000850040700000600030009080002000001"),
        make("golden-nugget", "Golden Nugget", null, null,
            "000000039000001005003050800008090006070002000100400000009080050020000600400700000"),
        make("platinum-blonde", "Platinum Blonde", null, null,
            "000000012000000003002300400001800005060070800000009000008500000900040500470006000"),
        make("unsolvable28", "Unsolvable #28", "David Filmer", null,
            "600008940900006100070040000200610000000000200089002000000060005000000030800001600"),
        make("unsolvable49", "Unsolvable #49", "David Filmer", null,
            "002800000030060007100000040600090000050600009000057060000300100070006008400000020"),
    )

    fun find(grid: Grid): LegendPuzzle? = all.firstOrNull { it.givens == grid }

    fun find(id: String): LegendPuzzle? = all.firstOrNull { it.id == id }

    private fun make(id: String, name: String, author: String?, year: Int?, grid: String) =
        LegendPuzzle(id, name, author, year, Grid.parse(grid)!!)
}
