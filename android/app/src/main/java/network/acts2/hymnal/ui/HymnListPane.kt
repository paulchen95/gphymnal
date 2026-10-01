package network.acts2.hymnal.ui

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import network.acts2.hymnal.HymnalViewModel
import network.acts2.hymnal.core.Hymn
import network.acts2.hymnal.ui.theme.Brand

/** The hymn list: search, A–Z sections with pinned letters, and the letter index down the side. */
@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun HymnListPane(vm: HymnalViewModel, listState: LazyListState, split: Boolean) {
    val sections = vm.sections
    val scope = rememberCoroutineScope()

    Scaffold(
        containerColor = Brand.colors.paper,
        topBar = {
            Column(Modifier.background(Brand.colors.paper)) {
                TopAppBar(
                    title = {
                        Text("Hymns", fontFamily = Brand.titleFont, fontSize = 30.sp)
                    },
                    actions = {
                        IconButton(onClick = { vm.showSettings = true }) {
                            Icon(Icons.Rounded.Settings, contentDescription = "Settings")
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = Brand.colors.paper),
                )
                SearchField(vm)
            }
        },
        // Side by side, the player sits under the lyrics instead.
        bottomBar = { if (!split) MiniPlayerArea(vm, pageHymn = null) },
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            if (sections.isEmpty() && vm.query.isNotEmpty()) {
                NoSearchResults(vm.query)
            } else {
                LazyColumn(state = listState, contentPadding = PaddingValues(bottom = 12.dp)) {
                    for (section in sections) {
                        stickyHeader(key = "header-" + section.letter) {
                            Text(
                                section.letter,
                                Modifier
                                    .fillMaxWidth()
                                    .background(Brand.colors.paperDeep)
                                    .padding(horizontal = 20.dp, vertical = 4.dp),
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 14.sp,
                                color = Brand.colors.secondary,
                            )
                        }
                        items(section.hymns, key = { it.filename }) { hymn ->
                            HymnRow(
                                hymn,
                                selected = split && hymn.filename == vm.selected,
                                onClick = { vm.selected = hymn.filename },
                                // Side by side, double-tap plays, like double-click on the Mac.
                                onDoubleClick = if (split && vm.hasAudio(hymn)) {
                                    { vm.selected = hymn.filename; vm.play(hymn) }
                                } else null,
                            )
                            HorizontalDivider(Modifier.padding(start = 20.dp), color = MaterialTheme.colorScheme.outlineVariant)
                        }
                    }
                }
                if (vm.query.isEmpty()) {
                    SectionIndex(
                        letters = sections.map { it.letter },
                        onLetter = { letter ->
                            var index = 0
                            for (section in sections) {
                                if (section.letter == letter) break
                                index += 1 + section.hymns.size
                            }
                            scope.launch { listState.scrollToItem(index) }
                        },
                        modifier = Modifier.align(Alignment.CenterEnd),
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun HymnRow(hymn: Hymn, selected: Boolean, onClick: () -> Unit, onDoubleClick: (() -> Unit)?) {
    Text(
        hymn.name + if (hymn.isChristmas) " " + Hymn.CHRISTMAS_MARKER else "",
        Modifier
            .fillMaxWidth()
            .background(if (selected) Brand.colors.accent.copy(alpha = 0.16f) else Brand.colors.paper)
            .combinedClickable(onClick = onClick, onDoubleClick = onDoubleClick)
            .semantics { contentDescription = hymn.name + if (hymn.isChristmas) ", Christmas" else "" }
            // Clear of the letter index on the right.
            .padding(start = 20.dp, end = 36.dp, top = 13.dp, bottom = 13.dp),
        fontSize = 17.sp,
        color = Brand.colors.ink,
    )
}

@Composable
private fun SearchField(vm: HymnalViewModel) {
    val focusRequester = remember { FocusRequester() }
    val focusManager = LocalFocusManager.current
    LaunchedEffect(vm.focusSearchRequest) {
        if (vm.focusSearchRequest > 0) focusRequester.requestFocus()
    }
    TextField(
        value = vm.query,
        onValueChange = { vm.query = it },
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 6.dp)
            .focusRequester(focusRequester)
            .onFocusChanged { vm.searchFocused = it.isFocused },
        placeholder = { Text("Search titles and lyrics") },
        leadingIcon = { Icon(Icons.Rounded.Search, contentDescription = null) },
        trailingIcon = {
            if (vm.query.isNotEmpty()) {
                IconButton(onClick = { vm.query = "" }) {
                    Icon(Icons.Rounded.Close, contentDescription = "Clear search")
                }
            }
        },
        singleLine = true,
        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
        keyboardActions = androidx.compose.foundation.text.KeyboardActions(onSearch = { focusManager.clearFocus() }),
        shape = RoundedCornerShape(50),
        colors = TextFieldDefaults.colors(
            focusedContainerColor = Brand.colors.paperDeep,
            unfocusedContainerColor = Brand.colors.paperDeep,
            focusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent,
            unfocusedIndicatorColor = androidx.compose.ui.graphics.Color.Transparent,
        ),
    )
}

@Composable
private fun NoSearchResults(query: String) {
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(Icons.Rounded.Search, null, Modifier.size(48.dp), tint = Brand.colors.secondary)
        Text("No Results for “$query”", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        Text("Check the spelling or try a new search.", color = Brand.colors.secondary)
    }
}
