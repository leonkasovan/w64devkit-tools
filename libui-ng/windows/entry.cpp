// 8 april 2015
#include "uipriv_windows.hpp"

struct uiEntry {
	uiWindowsControl c;
	HWND hwnd;
	void (*onChanged)(uiEntry *, void *);
	void *onChangedData;
	BOOL inhibitChanged;
	void (*onEnter)(uiEntry *, void *);
	void *onEnterData;
	WNDPROC origWndProc;
};

static BOOL onWM_COMMAND(uiControl *c, HWND hwnd, WORD code, LRESULT *lResult)
{
	uiEntry *e = uiEntry(c);

	if (code != EN_CHANGE)
		return FALSE;
	if (e->inhibitChanged)
		return FALSE;
	(*(e->onChanged))(e, e->onChangedData);
	*lResult = 0;
	return TRUE;
}

static LRESULT CALLBACK entryWndProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	uiEntry *e;
	WNDPROC origProc;

	e = (uiEntry *)GetPropW(hwnd, L"LUDO_ENTRY_PTR");
	if (e != NULL) {
		origProc = e->origWndProc;
		if ((uMsg == WM_KEYDOWN || uMsg == WM_KEYUP) && wParam == VK_RETURN) {
			if (e->onEnter) {
				(*(e->onEnter))(e, e->onEnterData);
				return 0;
			}
		}
		if (uMsg == WM_CHAR && wParam == 0x0D) {
			if (e->onEnter) {
				(*(e->onEnter))(e, e->onEnterData);
				return 0;
			}
		}
		return CallWindowProcW(origProc, hwnd, uMsg, wParam, lParam);
	}
	return DefWindowProcW(hwnd, uMsg, wParam, lParam);
}

static void uiEntryDestroy(uiControl *c)
{
	uiEntry *e = uiEntry(c);

	RemovePropW(e->hwnd, L"LUDO_ENTRY_PTR");
	uiWindowsUnregisterWM_COMMANDHandler(e->hwnd);
	uiWindowsEnsureDestroyWindow(e->hwnd);
	uiFreeControl(uiControl(e));
}

uiWindowsControlAllDefaultsExceptDestroy(uiEntry)

// from http://msdn.microsoft.com/en-us/library/windows/desktop/dn742486.aspx#sizingandspacing
#define entryWidth 107 /* this is actually the shorter progress bar width, but Microsoft only indicates as wide as necessary */
#define entryHeight 14

static void uiEntryMinimumSize(uiWindowsControl *c, int *width, int *height)
{
	uiEntry *e = uiEntry(c);
	uiWindowsSizing sizing;
	int x, y;

	x = entryWidth;
	y = entryHeight;
	uiWindowsGetSizing(e->hwnd, &sizing);
	uiWindowsSizingDlgUnitsToPixels(&sizing, &x, &y);
	*width = x;
	*height = y;
}

static void defaultOnChanged(uiEntry *e, void *data)
{
	// do nothing
}

static void defaultOnEnter(uiEntry *e, void *data)
{
	// do nothing
}

char *uiEntryText(uiEntry *e)
{
	return uiWindowsWindowText(e->hwnd);
}

void uiEntrySetText(uiEntry *e, const char *text)
{
	int l;
	// doing this raises an EN_CHANGED
	e->inhibitChanged = TRUE;
	uiWindowsSetWindowText(e->hwnd, text);
	l = (int)strlen(text);
	// Only set the cursor if the entry has focus to avoid weird scrolling upon window
	// creation. Cursor placement is otherwise determined by mouse position upon click.
	if (GetFocus() == e->hwnd)
		Edit_SetSel(e->hwnd, l, l);
	e->inhibitChanged = FALSE;
	// don't queue the control for resize; entry sizes are independent of their contents
}

void uiEntryOnChanged(uiEntry *e, void (*f)(uiEntry *, void *), void *data)
{
	e->onChanged = f;
	e->onChangedData = data;
}

void uiEntryOnEnter(uiEntry *e, void (*f)(uiEntry *, void *), void *data)
{
	e->onEnter = f;
	e->onEnterData = data;
}

int uiEntryReadOnly(uiEntry *e)
{
	return (getStyle(e->hwnd) & ES_READONLY) != 0;
}

void uiEntrySetReadOnly(uiEntry *e, int readonly)
{
	if (Edit_SetReadOnly(e->hwnd, readonly) == 0)
		logLastError(L"error setting uiEntry read-only state");
}

static uiEntry *finishNewEntry(DWORD style)
{
	uiEntry *e;

	uiWindowsNewControl(uiEntry, e);

	e->hwnd = uiWindowsEnsureCreateControlHWND(WS_EX_CLIENTEDGE,
		L"edit", L"",
		style | ES_AUTOHSCROLL | ES_LEFT | ES_NOHIDESEL | WS_TABSTOP,
		hInstance, NULL,
		TRUE);

	uiWindowsRegisterWM_COMMANDHandler(e->hwnd, onWM_COMMAND, uiControl(e));
	uiEntryOnChanged(e, defaultOnChanged, NULL);
	uiEntryOnEnter(e, defaultOnEnter, NULL);

	// Subclass to intercept WM_KEYDOWN for Enter key
	SetPropW(e->hwnd, L"LUDO_ENTRY_PTR", (HANDLE)e);
	e->origWndProc = (WNDPROC)SetWindowLongPtrW(e->hwnd, GWLP_WNDPROC, (LONG_PTR)entryWndProc);

	return e;
}

uiEntry *uiNewEntry(void)
{
	return finishNewEntry(0);
}

uiEntry *uiNewPasswordEntry(void)
{
	return finishNewEntry(ES_PASSWORD);
}

uiEntry *uiNewSearchEntry(void)
{
	uiEntry *e;
	HRESULT hr;

	e = finishNewEntry(0);

	hr = SetWindowTheme(e->hwnd, L"SearchBoxEditComposited", NULL);
	if (hr != S_OK || !IsAppThemed()) {
		//TODO log: Failed to apply search box theme.
	}

	return e;
}
