package com.alexafer.sudokuno.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.KeyboardArrowRight
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

// --- Éléments communs aux écrans ---

const val SITE_URL = "https://zerrino.github.io/sudokuno/"
const val PRIVACY_URL = "https://zerrino.github.io/sudokuno/privacy.html"
const val LEGAL_URL = "https://zerrino.github.io/sudokuno/legal.html"

@Composable
internal fun SectionCard(title: String? = null, footer: String? = null, content: @Composable ColumnScope.() -> Unit) {
    val p = LocalPalette.current
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        title?.let { Text(it, color = p.secondaryText, style = MaterialTheme.typography.labelLarge, modifier = Modifier.padding(start = 8.dp)) }
        Column(Modifier.fillMaxWidth().card(p).padding(horizontal = 16.dp, vertical = 6.dp), content = content)
        footer?.let { Text(it, color = p.secondaryText, style = MaterialTheme.typography.labelMedium, modifier = Modifier.padding(horizontal = 8.dp)) }
    }
}

@Composable
internal fun LabeledRow(label: String, value: String) {
    Row(Modifier.fillMaxWidth().padding(vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, Modifier.weight(1f))
        Text(value, color = LocalPalette.current.secondaryText, fontWeight = FontWeight.Medium)
    }
}

@Composable
internal fun ToggleRow(label: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth().padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, Modifier.weight(1f))
        Switch(checked = checked, onCheckedChange = onChange)
    }
}

@Composable
internal fun LinkRow(label: String, tag: String? = null, onClick: () -> Unit) {
    Text(label, color = LocalPalette.current.accent, modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 12.dp)
        .let { if (tag != null) it.testTag(tag) else it })
}

@Composable
internal fun StatusLine(text: String, icon: androidx.compose.ui.graphics.vector.ImageVector, color: Color) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
        Icon(icon, null, tint = color, modifier = Modifier.size(18.dp))
        Text(text, color = color, fontWeight = FontWeight.SemiBold, style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
internal fun ChevronRow(label: String, onClick: () -> Unit) {
    val p = LocalPalette.current
    Row(Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(label, Modifier.weight(1f), fontWeight = FontWeight.Medium)
        Icon(Icons.AutoMirrored.Rounded.KeyboardArrowRight, null, tint = p.secondaryText)
    }
}
