from __future__ import annotations

import zipfile
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from xml.sax.saxutils import escape


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "presentation" / "recipe_clean_app_presentation.pptx"

EMU_PER_INCH = 914400
SLIDE_WIDTH = int(13.333333 * EMU_PER_INCH)
SLIDE_HEIGHT = int(7.5 * EMU_PER_INCH)

CREAM = "FFF8F2"
PEACH = "FFE3D5"
PEACH_LIGHT = "FFF0E8"
PRIMARY = "FF6B35"
SECONDARY = "2EC4B6"
DARK = "182026"
MUTED = "5F6B73"
WHITE = "FFFFFF"
BORDER = "F2D4C6"

REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"
OFFICE_REL = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"


def emu(value: float) -> int:
    return int(value * EMU_PER_INCH)


def xml_text(value: str) -> str:
    return escape(value)


def attr(value: str) -> str:
    return escape(value, {'"': "&quot;"})


def text_shape(
    shape_id: int,
    text: str,
    x: float,
    y: float,
    w: float,
    h: float,
    *,
    size: int = 24,
    color: str = DARK,
    bold: bool = False,
    align: str = "l",
    font: str = "Aptos",
) -> str:
    paragraphs = text.split("\n")
    p_xml = []
    for paragraph in paragraphs:
        p_xml.append(
            f"""
            <a:p>
              <a:pPr algn="{align}"/>
              <a:r>
                <a:rPr lang="fr-FR" sz="{size * 100}" b="{1 if bold else 0}">
                  <a:solidFill><a:srgbClr val="{color}"/></a:solidFill>
                  <a:latin typeface="{attr(font)}"/>
                </a:rPr>
                <a:t>{xml_text(paragraph)}</a:t>
              </a:r>
            </a:p>
            """
        )

    return f"""
    <p:sp>
      <p:nvSpPr>
        <p:cNvPr id="{shape_id}" name="Text {shape_id}"/>
        <p:cNvSpPr txBox="1"/>
        <p:nvPr/>
      </p:nvSpPr>
      <p:spPr>
        <a:xfrm>
          <a:off x="{emu(x)}" y="{emu(y)}"/>
          <a:ext cx="{emu(w)}" cy="{emu(h)}"/>
        </a:xfrm>
        <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
        <a:noFill/>
        <a:ln><a:noFill/></a:ln>
      </p:spPr>
      <p:txBody>
        <a:bodyPr wrap="square" rtlCol="0"/>
        <a:lstStyle/>
        {''.join(p_xml)}
      </p:txBody>
    </p:sp>
    """


def rect_shape(
    shape_id: int,
    x: float,
    y: float,
    w: float,
    h: float,
    *,
    fill: str = WHITE,
    line: str | None = BORDER,
    radius: bool = True,
) -> str:
    line_xml = (
        "<a:ln><a:noFill/></a:ln>"
        if line is None
        else f"""
        <a:ln w="12700">
          <a:solidFill><a:srgbClr val="{line}"/></a:solidFill>
        </a:ln>
        """
    )
    geometry = "roundRect" if radius else "rect"
    return f"""
    <p:sp>
      <p:nvSpPr>
        <p:cNvPr id="{shape_id}" name="Shape {shape_id}"/>
        <p:cNvSpPr/>
        <p:nvPr/>
      </p:nvSpPr>
      <p:spPr>
        <a:xfrm>
          <a:off x="{emu(x)}" y="{emu(y)}"/>
          <a:ext cx="{emu(w)}" cy="{emu(h)}"/>
        </a:xfrm>
        <a:prstGeom prst="{geometry}"><a:avLst/></a:prstGeom>
        <a:solidFill><a:srgbClr val="{fill}"/></a:solidFill>
        {line_xml}
      </p:spPr>
      <p:txBody><a:bodyPr/><a:lstStyle/><a:p/></p:txBody>
    </p:sp>
    """


def image_shape(
    shape_id: int,
    rel_id: str,
    name: str,
    x: float,
    y: float,
    w: float,
    h: float,
) -> str:
    return f"""
    <p:pic>
      <p:nvPicPr>
        <p:cNvPr id="{shape_id}" name="{attr(name)}" descr="{attr(name)}"/>
        <p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr>
        <p:nvPr/>
      </p:nvPicPr>
      <p:blipFill>
        <a:blip r:embed="{rel_id}"/>
        <a:stretch><a:fillRect/></a:stretch>
      </p:blipFill>
      <p:spPr>
        <a:xfrm>
          <a:off x="{emu(x)}" y="{emu(y)}"/>
          <a:ext cx="{emu(w)}" cy="{emu(h)}"/>
        </a:xfrm>
        <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
      </p:spPr>
    </p:pic>
    """


def jpeg_dimensions(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    index = 2
    while index < len(data):
        if data[index] != 0xFF:
            index += 1
            continue
        marker = data[index + 1]
        index += 2
        if marker in (0xD8, 0xD9):
            continue
        length = int.from_bytes(data[index : index + 2], "big")
        if marker in range(0xC0, 0xC4):
            height = int.from_bytes(data[index + 3 : index + 5], "big")
            width = int.from_bytes(data[index + 5 : index + 7], "big")
            return width, height
        index += length
    raise ValueError(f"Dimensions JPEG introuvables pour {path}")


@dataclass
class Slide:
    background: str = CREAM
    shapes: list[str] = field(default_factory=list)
    rels: list[tuple[str, str, str]] = field(default_factory=list)
    next_shape_id: int = 2
    next_rel_id: int = 2

    def add_text(self, *args, **kwargs) -> None:
        self.shapes.append(text_shape(self.next_shape_id, *args, **kwargs))
        self.next_shape_id += 1

    def add_rect(self, *args, **kwargs) -> None:
        self.shapes.append(rect_shape(self.next_shape_id, *args, **kwargs))
        self.next_shape_id += 1

    def add_image(self, image: Path, x: float, y: float, *, h: float) -> None:
        width, height = jpeg_dimensions(image)
        w = h * width / height
        rel_id = f"rId{self.next_rel_id}"
        self.next_rel_id += 1
        self.rels.append((rel_id, f"../media/{image.name}", "image"))
        self.shapes.append(
            image_shape(self.next_shape_id, rel_id, image.name, x, y, w, h)
        )
        self.next_shape_id += 1

    def add_card(
        self,
        title: str,
        body: str,
        x: float,
        y: float,
        w: float,
        h: float,
        *,
        fill: str = WHITE,
    ) -> None:
        self.add_rect(x, y, w, h, fill=fill)
        self.add_text(title, x + 0.22, y + 0.18, w - 0.44, 0.35, size=16, bold=True)
        self.add_text(body, x + 0.22, y + 0.62, w - 0.44, h - 0.76, size=12, color=MUTED)


def add_header(slide: Slide, eyebrow: str, title: str, subtitle: str | None = None) -> None:
    slide.add_text(eyebrow.upper(), 0.55, 0.32, 4.5, 0.28, size=10, color=PRIMARY, bold=True)
    slide.add_text(title, 0.55, 0.62, 8.8, 0.62, size=30, color=DARK, bold=True)
    if subtitle:
        slide.add_text(subtitle, 0.58, 1.25, 9.0, 0.45, size=14, color=MUTED)


def add_footer(slide: Slide, index: int) -> None:
    slide.add_text("Recipe Clean App", 0.55, 7.05, 3.0, 0.22, size=8, color=MUTED)
    slide.add_text(str(index).zfill(2), 12.25, 7.03, 0.5, 0.22, size=8, color=MUTED, align="r")


def bullet_text(items: list[str]) -> str:
    return "\n".join(f"• {item}" for item in items)


def build_slides() -> list[Slide]:
    shots = ROOT / "docs" / "screenshots"
    signup = shots / "01-signup.jpeg"
    login = shots / "02-login.jpeg"
    dashboard = shots / "03-dashboard-recipes.jpeg"
    favorites = shots / "04-favorites.jpeg"
    create = shots / "05-create-recipe.jpeg"

    slides: list[Slide] = []

    slide = Slide()
    slide.add_rect(0, 0, 13.333, 7.5, fill=CREAM, line=None, radius=False)
    slide.add_rect(7.6, 0, 5.733, 7.5, fill=PEACH, line=None, radius=False)
    slide.add_text("Recipe Clean App", 0.75, 0.95, 6.3, 0.85, size=38, bold=True)
    slide.add_text("Application mobile de recettes", 0.78, 1.82, 5.8, 0.36, size=18, color=PRIMARY, bold=True)
    slide.add_text(
        "Flutter • Firebase • Riverpod • Clean Architecture",
        0.78,
        2.35,
        5.8,
        0.36,
        size=15,
        color=MUTED,
    )
    slide.add_card(
        "Objectif",
        "Présenter une application complète : authentification, recettes, recherche, favoris et persistance cloud.",
        0.78,
        3.25,
        5.85,
        1.25,
        fill=WHITE,
    )
    slide.add_text("JeeriDev", 0.78, 6.55, 2.2, 0.3, size=13, color=MUTED, bold=True)
    slide.add_image(dashboard, 9.2, 0.82, h=5.9)
    slides.append(slide)

    slide = Slide()
    add_header(
        slide,
        "Contexte",
        "Pourquoi cette application ?",
        "Une expérience mobile simple pour organiser, retrouver et sauvegarder des recettes.",
    )
    slide.add_card(
        "Problème",
        "Les recettes sont souvent dispersées entre notes, captures et favoris non structurés.",
        0.65,
        2.0,
        3.75,
        1.45,
    )
    slide.add_card(
        "Solution",
        "Un espace personnel connecté à Firebase, consultable rapidement depuis mobile.",
        4.8,
        2.0,
        3.75,
        1.45,
    )
    slide.add_card(
        "Résultat",
        "Une base Flutter maintenable, testée, et prête pour une démonstration académique.",
        8.95,
        2.0,
        3.75,
        1.45,
    )
    slide.add_text(
        bullet_text(
            [
                "Créer un compte et se connecter",
                "Consulter, rechercher et filtrer les recettes",
                "Ajouter une recette complète",
                "Gérer ses favoris par utilisateur",
            ]
        ),
        0.85,
        4.15,
        6.1,
        1.7,
        size=17,
        color=DARK,
    )
    slide.add_rect(7.55, 4.02, 4.6, 1.95, fill=PEACH_LIGHT)
    slide.add_text("Positionnement", 7.9, 4.35, 3.8, 0.3, size=17, bold=True)
    slide.add_text(
        "Une application de recettes qui montre autant le produit final que la qualité de l’architecture.",
        7.9,
        4.82,
        3.7,
        0.75,
        size=14,
        color=MUTED,
    )
    slides.append(slide)

    slide = Slide()
    add_header(slide, "Parcours", "Parcours utilisateur", "Du compte personnel à la consultation des recettes.")
    slide.add_image(signup, 0.9, 1.65, h=4.8)
    slide.add_text("Inscription", 1.1, 6.55, 1.7, 0.25, size=12, bold=True, align="c")
    slide.add_text("→", 3.35, 3.45, 0.6, 0.45, size=28, color=PRIMARY, bold=True, align="c")
    slide.add_image(login, 4.25, 1.65, h=4.8)
    slide.add_text("Connexion", 4.5, 6.55, 1.7, 0.25, size=12, bold=True, align="c")
    slide.add_text("→", 6.72, 3.45, 0.6, 0.45, size=28, color=PRIMARY, bold=True, align="c")
    slide.add_image(dashboard, 7.6, 1.65, h=4.8)
    slide.add_text("Recettes", 7.92, 6.55, 1.7, 0.25, size=12, bold=True, align="c")
    slide.add_card(
        "Navigation",
        "Les écrans secondaires gardent l’historique et affichent un bouton retour cohérent.",
        10.35,
        2.4,
        2.4,
        1.7,
        fill=WHITE,
    )
    slides.append(slide)

    slide = Slide()
    add_header(slide, "Fonctionnalités", "Tableau de bord des recettes")
    slide.add_image(dashboard, 0.85, 1.4, h=5.35)
    slide.add_text(
        bullet_text(
            [
                "Liste des recettes depuis Cloud Firestore",
                "Recherche par nom, description ou ingrédient",
                "Filtrage dynamique par catégorie",
                "Accès rapide aux favoris et à l’ajout",
            ]
        ),
        4.15,
        1.55,
        4.8,
        1.75,
        size=16,
        color=DARK,
    )
    slide.add_card("Recherche", "Filtre les recettes sans logique Firestore dans l’interface.", 4.2, 4.0, 2.55, 1.2)
    slide.add_card("Catégories", "Les catégories sont calculées depuis les données existantes.", 7.05, 4.0, 2.55, 1.2)
    slide.add_card("Action", "Le bouton Ajouter ouvre le formulaire en conservant le retour.", 9.9, 4.0, 2.55, 1.2)
    slides.append(slide)

    slide = Slide()
    add_header(slide, "Création", "Ajout d’une recette complète")
    slide.add_text(
        bullet_text(
            [
                "Nom, description, image et catégorie",
                "Difficulté et temps de cuisson",
                "Ingrédients ligne par ligne",
                "Étapes de préparation structurées",
                "Validation avant écriture Firestore",
            ]
        ),
        0.85,
        1.55,
        5.2,
        2.4,
        size=16,
        color=DARK,
    )
    slide.add_card(
        "Données propres",
        "Les chaînes sont nettoyées avant sauvegarde et une image par défaut est fournie si l’URL est vide.",
        0.85,
        4.55,
        5.4,
        1.25,
    )
    slide.add_image(create, 8.25, 0.95, h=5.95)
    slides.append(slide)

    slide = Slide()
    add_header(slide, "Favoris", "Favoris et expérience utilisateur")
    slide.add_image(favorites, 0.9, 1.5, h=5.15)
    slide.add_card(
        "Favoris par utilisateur",
        "Chaque utilisateur dispose de sa sous-collection dédiée dans Firestore.",
        4.05,
        1.65,
        3.7,
        1.35,
    )
    slide.add_card(
        "Retour clair",
        "Les écrans favoris et détails possèdent un bouton retour explicite.",
        8.25,
        1.65,
        3.7,
        1.35,
    )
    slide.add_card(
        "États UI",
        "Chargement, erreur, vide et retry sont visibles et homogènes.",
        4.05,
        3.45,
        3.7,
        1.35,
    )
    slide.add_card(
        "Flux réactif",
        "La liste des favoris écoute à la fois les recettes et les favoris.",
        8.25,
        3.45,
        3.7,
        1.35,
    )
    slides.append(slide)

    slide = Slide()
    add_header(slide, "Architecture", "Clean Architecture feature-first")
    layers = [
        ("Presentation", "Pages Flutter, widgets, Riverpod providers"),
        ("Application", "Use cases : filtrage, orchestration métier"),
        ("Domain", "Entités et contrats repositories"),
        ("Data / Infrastructure", "Firebase Auth, Firestore, models et datasources"),
    ]
    y = 1.45
    for index, (title, body) in enumerate(layers):
        fill = WHITE if index % 2 == 0 else PEACH_LIGHT
        slide.add_rect(0.85, y, 11.6, 0.85, fill=fill)
        slide.add_text(title, 1.15, y + 0.18, 2.6, 0.26, size=16, bold=True, color=PRIMARY)
        slide.add_text(body, 4.0, y + 0.2, 7.6, 0.26, size=14, color=DARK)
        if index < len(layers) - 1:
            slide.add_text("↓", 6.35, y + 0.82, 0.45, 0.28, size=18, color=SECONDARY, bold=True, align="c")
        y += 1.2
    slide.add_card(
        "Principe",
        "L’interface ne dépend pas directement de Firestore : elle passe par les providers, use cases et repositories.",
        1.1,
        6.25,
        10.9,
        0.72,
        fill=WHITE,
    )
    slides.append(slide)

    slide = Slide()
    add_header(slide, "Firebase", "Données, sécurité et persistance")
    slide.add_card("users/{userId}", "Profil utilisateur : email, nom complet, date de création.", 0.9, 1.55, 3.6, 1.2)
    slide.add_card("recipes/{recipeId}", "Recette : contenu, propriétaire, timestamps, listes d’ingrédients et étapes.", 4.85, 1.55, 3.6, 1.2)
    slide.add_card("favorites/{userId}/recipes", "Favoris séparés par utilisateur connecté.", 8.8, 1.55, 3.6, 1.2)
    slide.add_text(
        bullet_text(
            [
                "Lecture des recettes réservée aux utilisateurs connectés",
                "Création validée champ par champ dans firestore.rules",
                "Modification et suppression limitées au propriétaire",
                "Favoris accessibles uniquement par l’utilisateur concerné",
            ]
        ),
        1.05,
        3.55,
        6.7,
        1.75,
        size=15,
        color=DARK,
    )
    slide.add_rect(8.3, 3.55, 3.85, 1.55, fill=DARK)
    slide.add_text("Commande règles", 8.62, 3.82, 3.2, 0.25, size=13, color=WHITE, bold=True)
    slide.add_text(
        "firebase deploy --only\nfirestore:rules --project login-d11f5",
        8.62,
        4.23,
        3.1,
        0.6,
        size=12,
        color=PEACH,
        font="Consolas",
    )
    slides.append(slide)

    slide = Slide()
    add_header(slide, "Qualité", "Clean code et vérifications")
    slide.add_card("SOLID", "Responsabilités séparées entre pages, providers, use cases et repositories.", 0.85, 1.55, 3.65, 1.35)
    slide.add_card("Navigation", "Routes centralisées et bouton retour réutilisable.", 4.85, 1.55, 3.65, 1.35)
    slide.add_card("Tests", "Tests unitaires, widget test et modèle Firestore couverts.", 8.85, 1.55, 3.65, 1.35)
    slide.add_rect(1.1, 3.8, 11.0, 1.35, fill=DARK)
    slide.add_text("Résultat de vérification", 1.45, 4.08, 3.8, 0.3, size=16, color=WHITE, bold=True)
    slide.add_text(
        "dart format lib test\nflutter analyze  → No issues found\nflutter test     → All tests passed",
        5.0,
        3.98,
        5.8,
        0.78,
        size=13,
        color=PEACH,
        font="Consolas",
    )
    slide.add_card(
        "Point d’attention",
        "Le téléphone affichera permission-denied tant que les règles corrigées ne sont pas publiées dans Firebase.",
        2.0,
        5.75,
        9.3,
        0.9,
        fill=PEACH_LIGHT,
    )
    slides.append(slide)

    slide = Slide()
    slide.add_rect(0, 0, 13.333, 7.5, fill=DARK, line=None, radius=False)
    slide.add_text("Scénario de démonstration", 0.85, 0.9, 7.5, 0.65, size=32, color=WHITE, bold=True)
    slide.add_text(
        bullet_text(
            [
                "Créer un compte utilisateur",
                "Se connecter et afficher le tableau de bord",
                "Rechercher une recette et filtrer par catégorie",
                "Ajouter une nouvelle recette complète",
                "Marquer une recette comme favorite",
                "Revenir aux écrans précédents avec les boutons retour",
            ]
        ),
        1.0,
        2.0,
        7.25,
        2.35,
        size=17,
        color=WHITE,
    )
    slide.add_rect(8.8, 1.55, 3.3, 3.6, fill=PRIMARY, line=None)
    slide.add_text("Conclusion", 9.18, 2.0, 2.5, 0.35, size=20, color=WHITE, bold=True)
    slide.add_text(
        "Une app complète, lisible, testée, et structurée pour évoluer.",
        9.18,
        2.62,
        2.55,
        1.05,
        size=17,
        color=WHITE,
    )
    slide.add_text("Merci", 9.18, 4.25, 2.0, 0.45, size=22, color=WHITE, bold=True)
    slides.append(slide)

    for index, slide_item in enumerate(slides, start=1):
        if index not in (1, len(slides)):
            add_footer(slide_item, index)

    return slides


def slide_xml(slide: Slide) -> str:
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
       xmlns:r="{OFFICE_REL}"
       xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:bg>
      <p:bgPr>
        <a:solidFill><a:srgbClr val="{slide.background}"/></a:solidFill>
        <a:effectLst/>
      </p:bgPr>
    </p:bg>
    <p:spTree>
      <p:nvGrpSpPr>
        <p:cNvPr id="1" name=""/>
        <p:cNvGrpSpPr/>
        <p:nvPr/>
      </p:nvGrpSpPr>
      <p:grpSpPr>
        <a:xfrm>
          <a:off x="0" y="0"/>
          <a:ext cx="0" cy="0"/>
          <a:chOff x="0" y="0"/>
          <a:chExt cx="0" cy="0"/>
        </a:xfrm>
      </p:grpSpPr>
      {''.join(slide.shapes)}
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sld>
"""


def rels_xml(rels: list[tuple[str, str, str]]) -> str:
    type_map = {
        "officeDocument": f"{OFFICE_REL}/officeDocument",
        "slide": f"{OFFICE_REL}/slide",
        "slideMaster": f"{OFFICE_REL}/slideMaster",
        "slideLayout": f"{OFFICE_REL}/slideLayout",
        "theme": f"{OFFICE_REL}/theme",
        "image": f"{OFFICE_REL}/image",
        "metadata/core-properties": "http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties",
        "extended-properties": f"{OFFICE_REL}/extended-properties",
    }
    body = "\n".join(
        f'<Relationship Id="{rel_id}" Type="{type_map[rel_type]}" Target="{attr(target)}"/>'
        for rel_id, target, rel_type in rels
    )
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="{REL_NS}">
{body}
</Relationships>
"""


def presentation_xml(slide_count: int) -> str:
    slide_ids = "\n".join(
        f'<p:sldId id="{255 + index}" r:id="rId{index + 1}"/>'
        for index in range(1, slide_count + 1)
    )
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
                xmlns:r="{OFFICE_REL}"
                xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:sldMasterIdLst>
    <p:sldMasterId id="2147483648" r:id="rId1"/>
  </p:sldMasterIdLst>
  <p:sldIdLst>
    {slide_ids}
  </p:sldIdLst>
  <p:sldSz cx="{SLIDE_WIDTH}" cy="{SLIDE_HEIGHT}" type="screen16x9"/>
  <p:notesSz cx="6858000" cy="9144000"/>
  <p:defaultTextStyle>
    <a:defPPr>
      <a:defRPr lang="fr-FR"/>
    </a:defPPr>
  </p:defaultTextStyle>
</p:presentation>
"""


def content_types(slide_count: int) -> str:
    slide_overrides = "\n".join(
        f'<Override PartName="/ppt/slides/slide{index}.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>'
        for index in range(1, slide_count + 1)
    )
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Default Extension="jpeg" ContentType="image/jpeg"/>
  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>
  <Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>
  <Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>
  <Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
  {slide_overrides}
</Types>
"""


def slide_master_xml() -> str:
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
             xmlns:r="{OFFICE_REL}"
             xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:spTree>
      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
      <p:grpSpPr>
        <a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm>
      </p:grpSpPr>
    </p:spTree>
  </p:cSld>
  <p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>
  <p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rId1"/></p:sldLayoutIdLst>
  <p:txStyles>
    <p:titleStyle><a:lvl1pPr><a:defRPr sz="4400"/></a:lvl1pPr></p:titleStyle>
    <p:bodyStyle><a:lvl1pPr><a:defRPr sz="2800"/></a:lvl1pPr></p:bodyStyle>
    <p:otherStyle><a:lvl1pPr><a:defRPr sz="2200"/></a:lvl1pPr></p:otherStyle>
  </p:txStyles>
</p:sldMaster>
"""


def slide_layout_xml() -> str:
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
             xmlns:r="{OFFICE_REL}"
             xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"
             type="blank" preserve="1">
  <p:cSld name="Blank">
    <p:spTree>
      <p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>
      <p:grpSpPr>
        <a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm>
      </p:grpSpPr>
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr>
</p:sldLayout>
"""


def theme_xml() -> str:
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Recipe Clean Theme">
  <a:themeElements>
    <a:clrScheme name="Recipe">
      <a:dk1><a:srgbClr val="{DARK}"/></a:dk1>
      <a:lt1><a:srgbClr val="{CREAM}"/></a:lt1>
      <a:dk2><a:srgbClr val="1F2933"/></a:dk2>
      <a:lt2><a:srgbClr val="{WHITE}"/></a:lt2>
      <a:accent1><a:srgbClr val="{PRIMARY}"/></a:accent1>
      <a:accent2><a:srgbClr val="{SECONDARY}"/></a:accent2>
      <a:accent3><a:srgbClr val="{PEACH}"/></a:accent3>
      <a:accent4><a:srgbClr val="FFD166"/></a:accent4>
      <a:accent5><a:srgbClr val="5F6B73"/></a:accent5>
      <a:accent6><a:srgbClr val="8D99AE"/></a:accent6>
      <a:hlink><a:srgbClr val="0563C1"/></a:hlink>
      <a:folHlink><a:srgbClr val="954F72"/></a:folHlink>
    </a:clrScheme>
    <a:fontScheme name="Recipe Fonts">
      <a:majorFont><a:latin typeface="Aptos Display"/></a:majorFont>
      <a:minorFont><a:latin typeface="Aptos"/></a:minorFont>
    </a:fontScheme>
    <a:fmtScheme name="Recipe Format">
      <a:fillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:fillStyleLst>
      <a:lnStyleLst><a:ln w="12700"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln></a:lnStyleLst>
      <a:effectStyleLst><a:effectStyle><a:effectLst/></a:effectStyle></a:effectStyleLst>
      <a:bgFillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:bgFillStyleLst>
    </a:fmtScheme>
  </a:themeElements>
  <a:objectDefaults/>
  <a:extraClrSchemeLst/>
</a:theme>
"""


def core_props_xml() -> str:
    now = datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
                   xmlns:dc="http://purl.org/dc/elements/1.1/"
                   xmlns:dcterms="http://purl.org/dc/terms/"
                   xmlns:dcmitype="http://purl.org/dc/dcmitype/"
                   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>Recipe Clean App - Présentation</dc:title>
  <dc:subject>Présentation de l'application mobile Flutter</dc:subject>
  <dc:creator>JeeriDev</dc:creator>
  <cp:lastModifiedBy>Codex</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">{now}</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">{now}</dcterms:modified>
</cp:coreProperties>
"""


def app_props_xml(slide_count: int) -> str:
    return f"""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"
            xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Microsoft PowerPoint</Application>
  <PresentationFormat>On-screen Show (16:9)</PresentationFormat>
  <Slides>{slide_count}</Slides>
  <Notes>0</Notes>
  <Company>JeeriDev</Company>
</Properties>
"""


def write_presentation(slides: list[Slide]) -> None:
    media_sources = sorted(
        {
            ROOT / "docs" / "screenshots" / rel_target.replace("../media/", "")
            for slide in slides
            for _, rel_target, rel_type in slide.rels
            if rel_type == "image"
        }
    )

    if OUTPUT.exists():
        OUTPUT.unlink()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(OUTPUT, "w", zipfile.ZIP_DEFLATED) as pptx:
        pptx.writestr("[Content_Types].xml", content_types(len(slides)))
        pptx.writestr(
            "_rels/.rels",
            rels_xml(
                [
                    ("rId1", "ppt/presentation.xml", "officeDocument"),
                    ("rId2", "docProps/core.xml", "metadata/core-properties"),
                    ("rId3", "docProps/app.xml", "extended-properties"),
                ]
            ),
        )
        pptx.writestr("docProps/core.xml", core_props_xml())
        pptx.writestr("docProps/app.xml", app_props_xml(len(slides)))
        pptx.writestr("ppt/presentation.xml", presentation_xml(len(slides)))
        pptx.writestr(
            "ppt/_rels/presentation.xml.rels",
            rels_xml(
                [("rId1", "slideMasters/slideMaster1.xml", "slideMaster")]
                + [
                    (f"rId{index + 1}", f"slides/slide{index}.xml", "slide")
                    for index in range(1, len(slides) + 1)
                ]
            ),
        )
        pptx.writestr("ppt/slideMasters/slideMaster1.xml", slide_master_xml())
        pptx.writestr(
            "ppt/slideMasters/_rels/slideMaster1.xml.rels",
            rels_xml(
                [
                    ("rId1", "../slideLayouts/slideLayout1.xml", "slideLayout"),
                    ("rId2", "../theme/theme1.xml", "theme"),
                ]
            ),
        )
        pptx.writestr("ppt/slideLayouts/slideLayout1.xml", slide_layout_xml())
        pptx.writestr(
            "ppt/slideLayouts/_rels/slideLayout1.xml.rels",
            rels_xml([("rId1", "../slideMasters/slideMaster1.xml", "slideMaster")]),
        )
        pptx.writestr("ppt/theme/theme1.xml", theme_xml())

        for index, slide in enumerate(slides, start=1):
            pptx.writestr(f"ppt/slides/slide{index}.xml", slide_xml(slide))
            pptx.writestr(
                f"ppt/slides/_rels/slide{index}.xml.rels",
                rels_xml([("rId1", "../slideLayouts/slideLayout1.xml", "slideLayout")] + slide.rels),
            )

        for source in media_sources:
            pptx.write(source, f"ppt/media/{source.name}")


def main() -> None:
    slides = build_slides()
    write_presentation(slides)
    print(OUTPUT)


if __name__ == "__main__":
    main()
