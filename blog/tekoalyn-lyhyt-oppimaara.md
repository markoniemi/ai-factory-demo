---
title: Tekoälyn lyhyt oppimäärä
---

# Tekoälyn lyhyt oppimäärä

## Muotisanat

- **LLM**: suuri kielimalli, joka ennustaa seuraavan sanan
- **Token**: sanan pala, jonka mukaan laskutetaan ja jonka verran malli jaksaa lukea
- **Prompt**: malille annettu ohje
- **Kontekstiikkuna (context window)**: kaikki, mitä malli näkee kerralla
- **Agentti**: malli, joka käyttää työkaluja itsenäisesti
- **Skill**: valmis ohjepaketti tiettyyn tehtävään
- **MCP**: yhteinen tapa liittää työkaluja malliin
- **RAG**: tiedon haku promptiin ennen vastausta
- **Hallusinaatio**: uskottavalta kuulostava mutta väärä vastaus
- **Embedding**: tekstin lukuesitys, jolla haetaan samankaltaista tekstiä

## Tausta

Nykyiset kielimallit ovat kaukaisia sukulaisia Markovin ketjulle: seuraava sana arvataan edellisten perusteella. Idea on yli sata vuotta vanha. Sen historiasta kertoo Veritasiumin video [The Strange Math That Predicts (Almost) Anything](https://www.youtube.com/watch?v=KZeIEiBrT_w).

## Miten tekoäly toimii

Malli lukee tekstin tokeneina ja ennustaa yhden uuden tokenin kerrallaan. Mitä enemmän tokeneita, sitä enemmän aikaa ja rahaa kuluu. Siksi tokenit kannattaa pitää minimissä. Sisäisen toiminnan selittää hyvin 3Blue1Brownin video [Transformers, the tech behind LLMs](https://www.youtube.com/watch?v=wjZofJX0v4M).

## Miten tekoälyä käytetään tehokkaasti

### Skills

Skill on lyhyt ohje tietylle työlle, esimerkiksi koodikatselmoinnille. Se ladataan kontekstiin, joten pitkä skill syö tilaa muulta. Pidä se lyhyenä.

### Ohjetiedosto

Ohjetiedosto (esim. `CLAUDE.md`) luetaan jokaisen istunnon alussa. Kirjoita siihen vain olennainen ja viittaa tarvittaessa muihin tiedostoihin.

### README-tiedostot

README kuuluu repon juureen ja tarvittaessa jokaiseen moduuliin. Siinä kerrotaan, mihin projekti on tarkoitettu, miten sen ajaa ja miten se on rakennettu.

### MCP

MCP antaa mallille tyypitetyt työkalut ja yhteisen tunnistautumisen, kun CLI-työkalun tulosteet pitäisi muuten tulkita tekstistä. Jokainen MCP lisää työkalukuvauksia kontekstiin, joten käytä vain tarvitsemiasi.

### RAG

RAG hakee olennaiset dokumentit promptiin ennen vastausta. Se sopii suurelle tai usein muuttuvalle tietomäärälle. Pienelle ja vakaalle aineistolle riittää tiedoston liittäminen suoraan.

### Konteksti

Konteksti on kaikki, minkä malli näkee kerralla. Pidä se pienenä: lyhyet ohjeet, uusi istunto jokaiselle tehtävälle, tiivistä pitkät keskustelut ja hae vain tarvittava tieto.

### Suunnittelu

Tee ensin suunnitelma, sitten toteutussuunnitelma ja toteuta vaiheittain. Virhe on halvempi korjata suunnitelmassa kuin koodissa, ja pienet vaiheet on helppo tarkastaa.

### AI-koodausloop eli AI-tehdas

AI-tehdas on silmukka, jossa tehtävä etenee tilasta toiseen: luonnos, suunnittelu, toteutus, katselmointi ja yhdistäminen. Tekoäly tekee työn, ihminen hyväksyy suunnitelman ja lopputuloksen.
