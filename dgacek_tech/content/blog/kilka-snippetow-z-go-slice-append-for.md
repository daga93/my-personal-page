+++
date = '2026-02-05T10:50:15+01:00'
draft = true
title = 'Kilka snippetów z Go, które testują wiedzę o mechanice języka'
+++

# Kilkulinijkowce z Go o Slice, Strings, Append i For


Poniżej kilka snippetów sprawdzających rozumienie języka Go. Dotycza one Stringów, Unicode, Tablic oraz Slice.
Wiele z tych przykładów są wymyślone, raczej nie zoabczymy produkcyjnego kodu który z nich korzysta. Ale pomagają zrozumieć zasadę dzialania języka Go.

## Strings, Runes
Dlaczego ten kod nie wyświetli 2 tylko 3?
```go
func main() {
    fmt.Println(len("że"))
}
```
Dzieje się tak dlatego, że Go używa enkodowania UTF-8 które używa konceptu code pointów w odniesiu do reprezentacji znaku. UTF-8 enkoduje znaki w 1-4 bajtach (do 32 bitów). Rune to w Go alias do int32 wlaśnie z tego powodu. Proste znaki są kdowane jako pojedynczy bajt, ale te niestandardowe jak "ż" to kilka bajtów. Dlatego jeżeli zrobimy coś takiego:

```go
func main() {
    fmt.Println([]byte("ż"))
}
```
Output to będzie lista 2 elementowa:
```sh
[197 188]
```
---
## Slice oraz append
Ten przykład sprawdza znajomość tego co to jest slice, jak jest zbudowany i jak działa. W książce "Język Go. Poznaj i programuj" autorstwa Donovan A.A Alan Kernighan Brian W, znalazłem taką definicję Wycinka (Slice):
> Wycinek jest lekką strukturą danych, dającą dostęp do podsekwencji (albo do wszystkich) elementów tablicy, która jest określana jako bazowa tablica wycinka. Wycinek ma trzy komponenty: wskaźnik, długość i 
Slice wskazuje do podstawowej tablicy - to powinno pomóc rozwiązać poniższy problem:
```go
package main

import "fmt"

func main() {
	a := []int{1, 2, 3}
	b := a[:2]
	c := append(b, 4)
	a[1] = 99

	fmt.Println(a)
	fmt.Println(b)
	fmt.Println(c)
}

```
{{< reveal  >}}
```go
[1 99 4]
[1 99]
[1 99 4]
```
{{< /reveal >}}
1. W pierwszej linii main() definiujemy zmienną a jako slice intów. W tym przypadku `len=3, cap=3`.
2. Następnie bierzemy slice'a od 0 do 2 elementu. Slice będzie miał wartości - `{1, 2}, len=2, cap=3`.
3. Dodajemy element do slice (4) do `b`. `b` ma `len=2` a `cap=3`, dlatego 4 jest wstawiane do następnego miejsca w pamięci. Wartość `c` = `{1, 2, 4}`.
4. Do pierwszego elementu `a` przypisujemy 99. Nalezy pamiętać, że Slice jest wskaźnikiem do tablicy!

- `a` to wartości `[1 99 4]`. Ostatni element został nadpisany podczas `c := append(b, 4)`. Drugi przy wywołaniu `a[1] = 99`.
- `b` to wartości `[1 99]`. Nie zmienila się długość b. Jako że wskazuje on na tą samą tablicę, zamiast 2 mamy 99.
- `c` to wartości `[1 99 4]`.

Na co warto zwrócić uwagę przy tym przykładzie, z książki Jona Bodner'a:
> To avoid complicated slice situations, you should either never use append with a subslice or make sure that append doesn’t cause an overwrite by using a full slice expression. This is a little weird, but it makes clear how much memory is shared between the parent slice and the subslice


No dobrze, a co w takim razie z przykładem, kiedy subslice miałby len=cap?

---
## Slice, Subslice oraz append kiedy Subslice len=cap
To przypadek tłumaczący to, co dzieje się pod spodem - z tablicą na której oparty jest Slice. Jaki będzie output z wykonania tego programu, czy `a[1]` będzie 1 czy 0?
```go
package main

import "fmt"

func main() {
	a := []int{1, 2, 3}
	b := a[1:]          
	b = append(b, 4) 
	b[0] = 0

	fmt.Println(a)
	fmt.Println(b)
}
```
{{< reveal  >}}
```go
[1 2 3]
[0 3 4]
```
{{< /reveal >}}

1. `b` to Slice (Subslice `a`). `len=2, cap=2`, tak więc jest zapełniony.
2. Dodajemy kolejny element do b. Slice jest już pełny - Go tworzy nową tablicę o wiekszej pojemności, i kopiuje wszystkie elementy a następnie wstawia 4.
3. Do zerowego elementu `b` przypisujemy 0. Jako że pod spodem jest nowa tablica, `a[1]` pozostanie takie jak był, czyli 1.


Side Note: Zapytałem Gemini o odpowiedź. Model szybki udziela złej, model myślący poprawnej!

---
## Tablica ze wskaźnikami - nadpisanie in place
Mamy 10-cio elementową tablicę z wskaźnikami do bajtów. Jej pierwszy element ustawiamy jako wskaźnik zaincjowanego bajta, reszta wskazuje nil.
Jaki będzie wynik po uruchomieniu? 
```go
package main

import "fmt"

func main() {
	b1 := byte(2)
	a := [10]*byte{0: &b1}
	fmt.Println("Before:", *a[0])
	change(a)
	fmt.Println("After:", *a[0])

}

func change(a [10]*byte) {
	b := byte(29)
	a[0] = &b
}

```
{{< reveal  >}}
```go
Before: 2
After: 2
```
{{< /reveal >}}

Dlaczego tak?
1. Przekazujemy listę wskaźników, pierwszy z nich wskazuje na konkretny adres.
2. Wywołujemy funkcję. W wywołanej funkcji mamy kopię listy wskaźników.
3. Do tej **skopiowanej** listy - na pierwszym elemencie wstawiamy wskaźnik do zmiennej ``b`.
4. Wychodzimy z funkcji - **kopia** listy (z podstawionym elementem) przestaje istnieć.
5. Wypisane zostaje 2, a nie 29.

A jak podstawić tą wartość w miejscu? Wartość `b` należy przypisać do wartości bajtu wskazywanego przez `a[0]`:
```go
func change(a [10]*byte) {
	b := byte(29)
	*a[0] = b
}
```
---
## Pętla for oraz range
Jakie wartości zostaną wypisane w pierwszej oraz drugiej linii?
```go
package main

import "fmt"

type T struct{ v int }

func main() {
	ts := []T{{1}, {2}, {3}}
	var ptrs []*T

	for _, t := range ts {
		ptrs = append(ptrs, &t)
	}

	fmt.Println(ts[0].v, ts[1].v, ts[2].v)
	fmt.Println(ptrs[0].v, ptrs[1].v, ptrs[2].v)
}
```
{{< reveal  >}}
```go
1 2 3
1 2 3
```
{{< /reveal >}}

Skąd takie pytanie? To pytanie przeżyło już lata swojej świetności. Było bardzo ważne przed wersją Go 1.22. Inicjacja zmiennych w pętli for działa się wtedy tylko na początku. Adres `t` był więc w każdej iteracji ten sam, nadpisana było jego wartość. 
Dlatego przed wersją Go 1.22, powyższy kod zwracał:
```go
1 2 3
3 3 3
```
To było jedno z najbardziej powszechnych problemów/błędów na które trzeba było uważać. Więcej o tym [>> Go Common Mistakes <<](https://go.dev/wiki/CommonMistakes).