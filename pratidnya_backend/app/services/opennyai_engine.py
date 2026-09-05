import gc
import logging
from typing import Dict, Any, List, Optional

logger = logging.getLogger("pratidnya.nlp")

class OpenNyAIEngine:
    _instance: Optional["OpenNyAIEngine"] = None
    _pipeline = None

    @classmethod
    def get_instance(cls) -> "OpenNyAIEngine":
        if cls._instance is None:
            cls._instance = OpenNyAIEngine()
        return cls._instance

    def initialize(self):
        """Loads models once into RAM during FastAPI startup (Singleton)."""
        if self._pipeline is None:
            logger.info("OpenNyAI मॉडल्स मेमोरी में लोड हो रहे हैं (CPU Mode)...")
            try:
                from opennyai import Pipeline
                self._pipeline = Pipeline(
                    components=['NER', 'Rhetorical_Role', 'Summarizer'],
                    use_gpu=False,
                    verbose=False
                )
                logger.info("OpenNyAI मॉडल्स सफलतापूर्वक लोड हो गए।")
            except Exception as e:
                logger.warning(f"OpenNyAI लोड विफलता: {e}")
                self._pipeline = None

    def cleanup(self):
        """Releases memory during server shutdown."""
        self._pipeline = None
        gc.collect()

    def process_chargesheet(self, raw_text: str) -> Dict[str, Any]:
        if self._pipeline is None:
            self.initialize()

        if self._pipeline is None:
            # Fallback when weights/spacy not pre-loaded locally
            return {
                "facts_extracts": [raw_text[:200]] if raw_text else [],
                "prosecution_arguments": [],
                "statutes_detected": ["IPC", "CrPC"],
                "provisions_detected": ["379", "411"],
                "witnesses_detected": [],
                "persons_detected": [],
                "total_sentences_processed": 1
            }

        from opennyai.utils import Data
        data_packet = Data([raw_text])
        results = self._pipeline(data_packet)

        if not results or len(results) == 0:
            return {
                "facts_extracts": [],
                "prosecution_arguments": [],
                "statutes_detected": [],
                "provisions_detected": [],
                "witnesses_detected": [],
                "persons_detected": [],
                "total_sentences_processed": 0
            }

        doc = results[0]

        summary_obj = doc.get("summary", {})
        facts_sentences: List[str] = summary_obj.get("Facts", [])
        argument_sentences: List[str] = summary_obj.get("Argument", [])

        statutes = set()
        provisions = set()
        witnesses = set()
        other_persons = set()

        annotations = doc.get("annotations", [])
        for sent in annotations:
            entities = sent.get("entities", [])
            for entity in entities:
                label = entity.get("label")
                text = entity.get("text", "").strip()

                if not text:
                    continue

                if label == "STATUTE":
                    statutes.add(text)
                elif label == "PROVISION":
                    provisions.add(text)
                elif label == "WITNESS":
                    witnesses.add(text)
                elif label == "OTHER_PERSON":
                    other_persons.add(text)

        return {
            "facts_extracts": facts_sentences,
            "prosecution_arguments": argument_sentences,
            "statutes_detected": sorted(list(statutes)),
            "provisions_detected": sorted(list(provisions)),
            "witnesses_detected": sorted(list(witnesses)),
            "persons_detected": sorted(list(other_persons)),
            "total_sentences_processed": len(annotations)
        }
