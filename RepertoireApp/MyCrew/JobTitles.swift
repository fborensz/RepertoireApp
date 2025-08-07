// JobTitles.swift

import Foundation

struct JobTitles {
    // Métier spécial pour les imports (non visible dans les menus)
    static let defaultJob = "À définir"
    
    static let departments: [String: [String]] = [
        "Réalisation": [
            "Réalisateur",
            "1er Assistant Réalisateur",
            "2e Assistant Réalisateur",
            "3e Assistant Réalisateur",
            "Scripte"
        ],
        "Image": [
            "Directeur de la photographie",
            "Chef opérateur",
            "Cadreur",
            "Opérateur Steadicam",
            "Opérateur Louma",
            "1er Assistant Caméra (Focus Puller)",
            "2e Assistant Caméra (Clap/Loader)",
            "3e Assistant Caméra",
            "Vidéo Assist",
            "DIT (Digital Imaging Technician)",
            "Data Manager"
        ],
        "Son": [
            "Ingénieur du Son",
            "Perchman",
            "Assistant Son",
            "Sound Designer",
            "Monteur Son",
            "Mixeur"
        ],
        "Lumière": [
            "Chef Électro (Gaffer)",
            "Électro",
            "Chef Machiniste (Key Grip)",
            "Machiniste",
            "Rigger"
        ],
        "Régie": [
            "Régisseur Général",
            "Régisseur Adjoint",
            "Régisseur",
            "Assistant Régie",
            "Régisseur Transport",
            "Régisseur Plateau"
        ],
        "Décors": [
            "Chef Décorateur",
            "Assistant Décorateur",
            "Ensemblière",
            "Accessoiriste",
            "Peintre Décor",
            "Constructeur Décor",
            "Menuisier Décor",
            "Habilleur de Décor"
        ],
        "Costumes": [
            "Chef Costumier",
            "Assistant Costumier",
            "Habilleur",
            "Styliste",
            "Costumier"
        ],
        "Maquillage et Coiffure": [
            "Chef Maquilleur",
            "Maquilleur",
            "Assistant Maquilleur",
            "Chef Coiffeur",
            "Coiffeur",
            "Perruquier"
        ],
        "Production": [
            "Producteur",
            "Directeur de Production",
            "Assistant de Production",
            "Administrateur de Production",
            "Secrétaire de Production"
        ],
        "Post-Production": [
            "Monteur Image",
            "Assistant Monteur",
            "Étalonneur",
            "Superviseur VFX",
            "Graphiste VFX",
            "Motion Designer"
        ],
        "Autres Spécialités": [
            "Cascadeur",
            "Coordinateur Stunts",
            "Dresseur Animalier",
            "Photographe de Plateau",
            "Making-of",
            "Chef Cuisinier Plateau"
        ]
    ]
    
    // Fonction pour obtenir tous les métiers disponibles dans l'interface
    static var allAvailableJobs: [String] {
        return departments.values.flatMap { $0 }.sorted()
    }
    
    // Fonction pour vérifier si un métier est valide (inclut "À définir")
    static func isValidJob(_ job: String) -> Bool {
        return job == defaultJob || allAvailableJobs.contains(job)
    }
}
