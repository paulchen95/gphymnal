package network.acts2.hymnal.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.BorderColor
import androidx.compose.material.icons.rounded.Contrast
import androidx.compose.material.icons.rounded.Language
import androidx.compose.material.icons.rounded.UnfoldMore
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import network.acts2.hymnal.BuildConfig
import network.acts2.hymnal.HymnalViewModel
import network.acts2.hymnal.R
import network.acts2.hymnal.core.Hymn
import network.acts2.hymnal.core.Locales
import network.acts2.hymnal.core.LyricsTextSize
import network.acts2.hymnal.ui.theme.Brand

/** About, Language, Reading (text size and a preview), Display — the same as the Apple app. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(vm: HymnalViewModel, onDone: () -> Unit) {
    val settings = vm.settings
    Scaffold(
        containerColor = Brand.colors.paper,
        topBar = {
            TopAppBar(
                title = { Text("Settings", fontWeight = FontWeight.SemiBold) },
                actions = {
                    TextButton(onClick = onDone) { Text("Done", fontWeight = FontWeight.SemiBold) }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Brand.colors.paper),
            )
        },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.TopCenter) {
            Column(
                Modifier
                    .widthIn(max = 640.dp)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp)
                    .navigationBarsPadding(),
            ) {
                // About
                Group(footer = "A simple hymnal that works offline. Included music is royalty-free and copyright-free.") {
                    Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                        Image(
                            painterResource(R.mipmap.about_icon), null,
                            Modifier
                                .size(60.dp)
                                .clip(RoundedCornerShape(13.dp))
                                .border(1.dp, Brand.colors.ink.copy(alpha = 0.1f), RoundedCornerShape(13.dp)),
                        )
                        Spacer(Modifier.size(16.dp))
                        Column {
                            Text("A2N Hymnal", fontWeight = FontWeight.SemiBold, fontSize = 17.sp)
                            Text(
                                "Version ${BuildConfig.VERSION_NAME} (${BuildConfig.VERSION_CODE})",
                                color = Brand.colors.secondary,
                                fontSize = 15.sp,
                            )
                        }
                    }
                }

                // Language
                Group(footer = "Chinese translations are in beta.") {
                    var open by remember { mutableStateOf(false) }
                    Box {
                        SettingRow(icon = { Icon(Icons.Rounded.Language, null, tint = Brand.colors.accent) }, label = "Language", onClick = { open = true }) {
                            Text(Locales.all[settings.hymnLocale]?.name.orEmpty(), color = Brand.colors.secondary)
                            Icon(Icons.Rounded.UnfoldMore, null, Modifier.size(18.dp), tint = Brand.colors.secondary)
                        }
                        DropdownMenu(expanded = open, onDismissRequest = { open = false }, modifier = Modifier.align(Alignment.CenterEnd)) {
                            for ((code, locale) in Locales.all.entries.sortedBy { it.value.name }) {
                                DropdownMenuItem(
                                    text = { Text(locale.name) },
                                    onClick = {
                                        open = false
                                        if (code != settings.hymnLocale) {
                                            settings.hymnLocale = code
                                            vm.reload()
                                        }
                                    },
                                )
                            }
                        }
                    }
                }

                // Reading
                Group(header = "Reading") {
                    SettingRow(label = "Text Size") {
                        TextSizeControl(settings.lyricsTextSizeStep, { settings.lyricsTextSizeStep = it })
                    }
                    HorizontalDivider(Modifier.padding(start = 16.dp), color = MaterialTheme.colorScheme.outlineVariant)
                    val density = LocalDensity.current
                    val size = (LyricsTextSize.pointSize(settings.lyricsTextSizeStep, density.fontScale) / density.fontScale).sp
                    Text(
                        "Amazing grace! How sweet the sound\nThat saved a wretch like me!",
                        Modifier.padding(horizontal = 16.dp, vertical = 14.dp),
                        fontSize = size,
                        lineHeight = size * LyricsTextSize.LINE_HEIGHT,
                        color = Brand.colors.ink,
                    )
                }

                // Display
                Group(header = "Display", footer = "When you search, matching words in the lyrics are shown in red.") {
                    var appearanceMenu by remember { mutableStateOf(false) }
                    Box {
                        SettingRow(
                            icon = { Icon(Icons.Rounded.Contrast, null, tint = Brand.colors.accent) },
                            label = "Appearance",
                            onClick = { appearanceMenu = true },
                        ) {
                            Text(appearanceTitle(settings.appearance), color = Brand.colors.secondary)
                            Icon(Icons.Rounded.UnfoldMore, null, Modifier.size(18.dp), tint = Brand.colors.secondary)
                        }
                        DropdownMenu(
                            expanded = appearanceMenu,
                            onDismissRequest = { appearanceMenu = false },
                            modifier = Modifier.align(Alignment.CenterEnd),
                        ) {
                            for (option in listOf("system", "light", "dark")) {
                                DropdownMenuItem(
                                    text = { Text(appearanceTitle(option)) },
                                    onClick = {
                                        appearanceMenu = false
                                        settings.appearance = option
                                    },
                                )
                            }
                        }
                    }
                    HorizontalDivider(Modifier.padding(start = 56.dp), color = MaterialTheme.colorScheme.outlineVariant)
                    SettingRow(
                        icon = { Text(Hymn.CHRISTMAS_MARKER, fontSize = 20.sp) },
                        label = "Christmas Hymns",
                        onClick = { settings.showChristmas = !settings.showChristmas },
                    ) {
                        BrandSwitch(settings.showChristmas) { settings.showChristmas = it }
                    }
                    HorizontalDivider(Modifier.padding(start = 56.dp), color = MaterialTheme.colorScheme.outlineVariant)
                    SettingRow(
                        icon = { Icon(Icons.Rounded.BorderColor, null, tint = Brand.colors.accent) },
                        label = "Highlight Search Matches",
                        onClick = { settings.enableSearchHighlighting = !settings.enableSearchHighlighting },
                    ) {
                        BrandSwitch(settings.enableSearchHighlighting) { settings.enableSearchHighlighting = it }
                    }
                }
            }
        }
    }
}

@Composable
private fun Group(header: String? = null, footer: String? = null, content: @Composable ColumnScope.() -> Unit) {
    Column(Modifier.padding(top = 20.dp)) {
        if (header != null) {
            Text(
                header.uppercase(),
                Modifier.padding(start = 16.dp, bottom = 6.dp),
                fontSize = 13.sp,
                color = Brand.colors.secondary,
            )
        }
        Column(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(12.dp))
                .background(Brand.colors.surface),
            content = content,
        )
        if (footer != null) {
            Text(
                footer,
                Modifier.padding(start = 16.dp, end = 16.dp, top = 6.dp),
                fontSize = 13.sp,
                color = Brand.colors.secondary,
            )
        }
    }
}

@Composable
private fun SettingRow(
    label: String,
    icon: (@Composable () -> Unit)? = null,
    onClick: (() -> Unit)? = null,
    trailing: @Composable () -> Unit,
) {
    Row(
        Modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(horizontal = 16.dp, vertical = 6.dp)
            .padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        if (icon != null) Box(Modifier.size(28.dp), contentAlignment = Alignment.Center) { icon() }
        Text(label, Modifier.weight(1f), fontSize = 17.sp, color = Brand.colors.ink)
        trailing()
    }
}

@Composable
private fun BrandSwitch(checked: Boolean, onChange: (Boolean) -> Unit) {
    Switch(
        checked = checked,
        onCheckedChange = onChange,
        colors = SwitchDefaults.colors(
            checkedTrackColor = Brand.colors.accent,
            checkedThumbColor = Brand.colors.onAccent,
        ),
    )
}

private fun appearanceTitle(value: String) = when (value) {
    "light" -> "Light"
    "dark" -> "Dark"
    else -> "System"
}
