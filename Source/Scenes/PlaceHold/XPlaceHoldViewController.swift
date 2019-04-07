//
//  XPlaceHoldViewController.swift
//  X is for teXture
//
//  Copyright (C) 2018 Kenneth H. Cox
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

import AsyncDisplayKit

class XPlaceHoldViewController: ASViewController<ASDisplayNode> {
    let containerNode = ASDisplayNode()
    let scrollNode = ASScrollNode()
    let titleNode = ASTextNode()
    let subtitleNode = ASTextNode()
    let summaryNode = ASTextNode()
    
    //MARK: - Lifecycle
    
    init() {
        super.init(node: containerNode)
        self.title = "Scroll Node"
        scrollNode.automaticallyManagesSubnodes = true
        scrollNode.automaticallyManagesContentSize = true
        scrollNode.layoutSpecBlock = { node, constrainedSize in
            let stack = ASStackLayoutSpec.vertical()
            stack.children = [self.titleNode, self.subtitleNode, self.summaryNode]
            return stack
        }
        
        // See XDetailsNode and
        // https://github.com/TextureGroup/Texture/issues/774
        containerNode.automaticallyManagesSubnodes = true
        containerNode.layoutSpecBlock = { node, constrainedSize in
            return ASWrapperLayoutSpec(layoutElement: self.scrollNode)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        setupNodes()
    }
    
    func setupNodes() {
        titleNode.attributedText = makeText("The Cat in the Hat", ofSize: 24)
        subtitleNode.attributedText = makeText("Dr. Suess", ofSize: 18)
        if Bool.random() {
            summaryNode.attributedText = makeText("""
Simpatia familiar sin profunda uso inocente ver don victimas serafina. Al se il escapado musculos asfixiar citacion ha pormenor variable. Exceso hechos zamora en el ensayo ha oh. La beato dicho no malas. Valle me facil es honor. Sofa cual he cola daba no eres ante.

Aca muriendose soplandose convertido mas impregnado seduciendo. Volver mis corria esa soltar lengua tal ley. Yo no un os pasos todas suero casar comia. Siguiente yo cincuenta exagerado le taciturno. Ese esposo ajenas simple ser vulgar tal. Quien sus van apuro hueco bolsa hacer ellas.

Ma raso malo duro mala ni vivo cada. Me violento pariente el cuarenta ay. Tampoco no caseros modesto morales vapores ha el intimas. Si conquistas provincial reprimenda da. Fugitivo perpetua entendia la lo. Vez doy acabara esa estudio dormian saquito. Fulano ir jugado cortar ma buenas no. Infiernos asquerosa preterita envolvian hay iba correrias artistica.

Que temblar rey esbelto una bosques canario con. Asperos han pan asi egoismo delitos memoria perfume echarse. Rio gentilicio bastidores acompanado sacrosanta dispersado envejecido ser. Edad creo tu se oido tipo. Segun yo parar si ebano habla manso he amaba en. Voz saludado mermados reclamar delicada dos cogiendo. So avis malo flor nada yo tuvo yo esas. La si bastidores ah magistrado aspiracion sr escudrinar deliciosos ordinarios. Ido dice como unas seis rara por. Saludado suspiros al obsequia el adjetivo catadura.

Respetable ventajosos del asi sonoliento valladolid espectador eso. Si real toda ocho juro al casi ma rico al. Querida dejarse de lejanos te un va oficios. Conciertos poniendose amabilidad los mar. Saboreaba irritante acostados tu me cubiertas. Oro ahogando pretexto por amorosas encendia guitarra iba voluntad. Ruina atras el usaba ha mejor amico. Ese sencillo calzarse gravedad equipaje mal. Programa esa rio viviente resolvio publicas.

Distantes ti discipula siniestro resignada esplendor al maniobras. Provincial abofeteado fue escudrinar murmuraban aca ahi iba. Mimbre una gestos pan ido mareos brusco. Yo os alguna molino ha locura fuente tapete. Aturdida vacilado es otorgado le de. Casi ocho se ya la mano faro toco otra.

Causaban encargar el lo atrasado verrinas almanzor el un. Superior estrecha il en excesiva la. Ninguno en sacudio eh curador piernas es la derribo. Ya religiosa destacaba un en presentar ocupacion fioriture carinosos oh. Coristas ma si sobrinos oh de crimenes contacto. Humor las primo sea mas duros vista epoca don miles. Por nepomuceno contrastes cementerio que mas adulterios respetable misteriosa tal. Molesto fue poblado dia amorosa sea conatos don analogo. Una hay cada dio buen alto del.

Cantando las guitarra vendaval del descuido atrasado. Mil uno perfume sarebbe procuro era recibio modesto proximo. Ma si desafiar gritaron programa la. Fue ciudadano son luz atreveria resignado. Exacta paloma de sr queria. Nos mil cabrero excesos ver tapetes modales los manejos. Taciturno yo estuviese inclinaba gr admirando presencia se so. Fue comunes mas promesa soplaba tenerla curador lastima.

Ido dos escondite tentativa eso protegida miserable. Fuente hurano senora eso uso amable asusta con pedazo. Mar los lengua maloso vestia graves plazos. Arrastro ocupaban haciendo memorias nerviosa un ni. Un santiago el yo encogido sorpresa de. Superiores costumbres ch fantastico convertido el sacamuelas le. Esa tuvo van gris anos paje algo para.

Juro pais esto pedi ma puso me sala ni. Este mia asi bazo que como. Grandezas mil sebastian esa provincia rio afeminado caprichos moralidad. Del otro sido ojos miro sea. Habilitado aspiracion sol espectador caprichoso relaciones taciturnos etc. Ningun tu eh vestir ma hombre podian alamos ni. Crispulo hombrese pertinaz solemnes esbeltos escribia va il da.
""")
        } else {
            summaryNode.attributedText = makeText("""
No summary today.
""")
        }
    }
    
    func makeText(_ str: String, ofSize size: CGFloat = 17) -> NSAttributedString {
        let text = NSAttributedString(string: str, attributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: size, weight: .semibold),
            NSAttributedString.Key.foregroundColor: UIColor.black
            ])
        return text
    }
    
    /*
     override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
     
     let imageWidth = 50.0
     let imageHeight = imageWidth * 1.6
     
     let lhsSpec = ASStackLayoutSpec.vertical()
     lhsSpec.style.flexShrink = 1.0
     lhsSpec.style.flexGrow = 1.0
     lhsSpec.style.preferredSize = CGSize(width: 0, height: imageHeight)
     spacerNode.style.flexShrink = 1.0
     spacerNode.style.flexGrow = 1.0
     lhsSpec.children = [titleNode, spacerNode, authorNode, formatNode]
     
     imageNode.style.preferredSize = CGSize(width: imageWidth, height: imageHeight)
     disclosureNode.style.preferredSize = CGSize(width: 27, height: 27)
     
     let rhsSpec = ASStackLayoutSpec(direction: .horizontal, spacing: 0, justifyContent: .start, alignItems: .center, children: [imageNode, disclosureNode])
     
     let rowSpec = ASStackLayoutSpec(direction: .horizontal,
     spacing: 8,
     justifyContent: .start,
     alignItems: .center,
     children: [lhsSpec, rhsSpec])
     
     let spec = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 4.0, left: 8.0, bottom: 4.0, right: 4.0), child: rowSpec)
     //print(spec.asciiArtString())
     return spec
     }
     */
}

