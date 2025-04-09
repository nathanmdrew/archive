"""Topic Modeling Analysis Application.

This module provides comprehensive functionality for topic modeling analysis:
- Topic modeling using BERTopic with sentence transformer embeddings
- Dynamic topic analysis and visualization
- Asynchronous model persistence and output generation
- Real-time visualization with background saving

The module uses BERTopic for topic modeling and integrates with a React-based
visualization system while maintaining persistent outputs for future reference.
"""

from __future__ import annotations

import asyncio
import gc
import json
import logging
from collections import Counter
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple, Union, Any, cast
from functools import lru_cache
import re

import nltk
import numpy as np
import pandas as pd
from bertopic import BERTopic
from nltk.corpus import stopwords
from sentence_transformers import SentenceTransformer
from umap import UMAP
import plotly.graph_objects as go
from sklearn.feature_extraction.text import CountVectorizer
from bertopic.vectorizers import ClassTfidfTransformer
from bertopic.representation import KeyBERTInspired, MaximalMarginalRelevance
from wordcloud import WordCloud
from scipy.stats import chi2_contingency
import plotly.express as px
from sklearn.metrics import cohen_kappa_score
from hdbscan import HDBSCAN
import matplotlib.pyplot as plt

from .core_types import (
    DataFrameType, StatusProtocol, PathLike, 
    StatusHandler, StatusEntry, BytesContent, 
    ClientSessionAlias, SessionProtocol,
    TopicKeywords, TopicDistribution, TopicVisualizationData,
    ModelProtocol
)
from . import config
from . import decorators
from . import visualization

logger = logging.getLogger(__name__)

__all__ = [
    'TopicModeler',
    'save_topic_modeling_outputs'
]

class TopicModeler:
    """Topic modeling using BERTopic with improved configuration."""
    
    def __init__(
        self,
        config_dict: Optional[Dict[str, Any]] = None,
        seed_topics: Optional[List[str]] = None,
        num_topics: Union[int, str] = "auto",
        status_manager: Optional[StatusProtocol] = None
    ) -> None:
        """Initialize topic modeler with seed topics."""
        try:
            # Initialize core components
            self._embedding_model = None
            self.model = None
            self.vectorizer_model = None
            self.umap_model = None
            self.topic_name_map = {}
            
            # Store parameters
            self.config = config_dict or config.TOPIC_MODELING.copy()
            self.seed_topics = seed_topics  # Don't fall back to defaults here
            self.num_topics = num_topics
            self.status_manager = status_manager
            
            # Initialize components
            self._embedding_model = SentenceTransformer(self.config['EMBEDDING']['model'])
            self.vectorizer_model = self._initialize_vectorizer()
            self.umap_model = self._initialize_umap()
            
            # Process seed topics and initialize model
            if self.seed_topics:
                self._process_seed_topics()
            
            self.model = BERTopic(**self._get_model_config())
            
            logger.info(f"Initialized TopicModeler with {len(self.seed_topics or [])} seed topics")
            
        except Exception as e:
            logger.error(f"Failed to initialize TopicModeler: {str(e)}")
            raise

    def _process_seed_topics(self) -> None:
        """Process seed topics into keywords and name mapping."""
        self.topic_keywords = []
        self.topic_name_map = {}
        
        for i, topic in enumerate(self.seed_topics):
            words = [w.strip() for w in topic.split(',')]
            topic_name = words[0]  # First term is the name
            self.topic_name_map[i] = topic_name
            self.topic_keywords.append(words)  # Use all terms as keywords

    def _get_model_config(self) -> Dict[str, Any]:
        """Get BERTopic configuration with seed topics."""
        config = {
            'nr_topics': self.num_topics,
            'min_topic_size': self.config['TOPIC']['min_topic_size'],
            'embedding_model': self._embedding_model,
            'vectorizer_model': self.vectorizer_model,
            'umap_model': self.umap_model,
            'calculate_probabilities': True,
            'verbose': True
        }
        
        # Only add seed topics if explicitly provided
        if self.seed_topics:
            self._process_seed_topics()  # Ensure topics are processed
            config['seed_topic_list'] = self.topic_keywords
            logger.info(f"Configured {len(self.topic_keywords)} seed topics")
        
        return config

    def _generate_topic_names(self, topics: List[int]) -> Dict[int, str]:
        """Map topics to their names."""
        topic_names = {}
        for topic_id in set(topics):
            if topic_id == -1:
                topic_names[topic_id] = "Other Topics"
            elif topic_id in self.topic_name_map:
                topic_names[topic_id] = self.topic_name_map[topic_id]
            else:
                # For any non-seed topics
                words = self.model.get_topic(topic_id)
                if words:
                    top_words = [word for word, _ in words[:3]]
                    topic_names[topic_id] = f"Topic {topic_id}: {', '.join(top_words)}"
                else:
                    topic_names[topic_id] = f"Topic {topic_id}"
        return topic_names

    @property
    def embedding_model(self) -> SentenceTransformer:
        """Get or initialize sentence transformer model.
        
        Returns:
            Initialized SentenceTransformer model
            
        Raises:
            RuntimeError: If model initialization fails
            
        Note:
            Uses lazy initialization to only load model when needed
        """
        if self._embedding_model is None:
            try:
                model_name = self.config['EMBEDDING']['model']
                self._embedding_model = SentenceTransformer(model_name)
                logger.info(f"Initialized embedding model: {model_name}")
            except Exception as e:
                logger.error(f"Failed to initialize embedding model: {str(e)}")
                raise RuntimeError(f"Failed to initialize embedding model: {str(e)}")
        return self._embedding_model

    def _validate_seed_topics(self, seed_topics: Optional[List[str]]) -> List[List[str]]:
        """Process and validate seed topics for guided topic modeling.
        
        Args:
            seed_topics: List of seed topic strings from config
                Each string should be comma-separated with first term as topic name/keyword
                Example: "health hazards, respiratory illness, lung disease"
                
        Returns:
            List[List[str]]: List of keyword lists for each topic
            
        Note:
            - First term serves as both topic name and keyword
            - All terms are used as keywords for topic modeling
            - Maintains lowercase format for consistent matching
            - Updates self.topic_name_map for topic name lookup
        """
        self.topic_name_map = {}
        
        if not seed_topics:
            logger.debug("No seed topics provided")
            return []
        
        try:
            validated_topics = []
            
            for i, topic in enumerate(seed_topics):
                if not isinstance(topic, str):
                    logger.warning(f"Invalid topic format: {type(topic)}")
                    continue
                
                # Split and clean keywords (maintain lowercase)
                words = [w.strip().lower() for w in topic.split(',') if w.strip()]
                
                if len(words) >= 2:
                    topic_name = words[0]  # First term is both name and keyword
                    self.topic_name_map[topic_name] = topic_name
                    validated_topics.append(words)  # Use all terms as keywords
                    logger.debug(f"Validated topic {i}: {topic_name} ({len(words)} keywords)")
                else:
                    logger.warning(f"Insufficient keywords for topic {i}: {words}")
            
            logger.info(f"Processed {len(validated_topics)} seed topics")
            return validated_topics
            
        except Exception as e:
            logger.error(f"Error validating seed topics: {str(e)}")
            return []

    def _validate_embedding_model(self) -> None:
        """Validate embedding model compatibility."""
        try:
            model_name = self.config['EMBEDDING']['model']
            self._embedding_model = SentenceTransformer(model_name)
            
            # Validate model dimension compatibility
            test_text = "Test sentence for validation"
            embedding = self._embedding_model.encode([test_text])[0]
            expected_dim = self.config.get('EMBEDDING_DIM', embedding.shape[0])
            
            if embedding.shape[0] != expected_dim:
                raise ValueError(f"Embedding dimension mismatch: got {embedding.shape[0]}, expected {expected_dim}")
                
            logger.info(f"Validated embedding model: {model_name} (dim={embedding.shape[0]})")
            
        except Exception as e:
            error_msg = f"Embedding model validation failed: {str(e)}"
            logger.error(error_msg, exc_info=True)
            raise RuntimeError(error_msg)

    def _initialize_model(self, n_samples: int) -> None:
        """Initialize BERTopic model with configuration.
        
        Args:
            n_samples: Number of documents to process
            
        Raises:
            RuntimeError: If initialization fails
            
        Note:
            - Sets min_topic_size based on dataset size
            - Configures vectorizer for optimal feature extraction
            - Handles seed topics if provided
            - Adjusts parameters for small datasets
        """
        try:
            # Calculate dynamic min_topic_size based on dataset
            min_topic_size = max(
                min(int(n_samples * 0.05), 20),  # 5% of docs or 20, whichever is smaller
                5  # Lower minimum for small datasets
            )
            
            # Calculate max_features based on vocabulary size
            max_features = min(
                self.config.get('MAX_FEATURES', 20000),
                n_samples * 5  # Allow more features for better topic detection
            )
            
            logger.info(f"Initializing model with: min_topic_size={min_topic_size}, max_features={max_features}")
            
            # Configure model parameters
            model_params = {
                "embedding_model": self.embedding_model,
                "top_n_words": min(20, max(10, n_samples // 50)),
                "min_topic_size": min_topic_size,
                "nr_topics": "auto" if self.num_topics == "auto" else max(2, self.num_topics),
                "vectorizer_model": self._initialize_vectorizer(),
                "calculate_probabilities": True,
                "verbose": True
            }
            
            # Add seed topics if available
            if self.seed_topics:
                validated_topics = self._validate_seed_topics(self.seed_topics)
                if validated_topics:
                    model_params["seed_topic_list"] = validated_topics
                    logger.info(f"Using {len(validated_topics)} seed topics")
            
            logger.info(f"Model parameters: {model_params}")
            self.model = BERTopic(**model_params)
            
        except Exception as e:
            error_msg = f"Failed to initialize model: {str(e)}"
            logger.error(error_msg, exc_info=True)
            raise RuntimeError(error_msg)

    def cleanup(self) -> None:
        """Clean up model resources."""
        try:
            if self._embedding_model:
                del self._embedding_model
                self._embedding_model = None
            
            if self.model:
                del self.model
                self.model = None
            
            # Clear other attributes
            self.vectorizer_model = None
            self.umap_model = None
            
            gc.collect()
            logger.info("Cleaned up topic modeling resources")
            
        except Exception as e:
            logger.error(f"Error during cleanup: {str(e)}")

    @classmethod
    @decorators.async_handle_errors("Failed to load model")
    async def load_model(cls, path: Path) -> 'TopicModeler':
        """Load model from disk with validation.
        
        Args:
            path: Path to saved model
            
        Returns:
            Initialized TopicModeler instance
            
        Raises:
            ValueError: If loaded model is missing required components
        """
        instance = cls()
        instance.model = await asyncio.to_thread(BERTopic.load, str(path))
        
        required_attrs = ['embedding_model', 'umap_model', 'hdbscan_model']
        missing = [attr for attr in required_attrs if not hasattr(instance.model, attr)]
        if missing:
            raise ValueError(f"Loaded model missing components: {', '.join(missing)}")
            
        return instance

    def _generate_embeddings(
        self,
        texts: Union[List[str], pd.Series]
    ) -> np.ndarray:
        """Generate document embeddings efficiently.
        
        Handles both single batch and large-scale document embedding with
        memory-efficient batch processing.
        
        Args:
            texts: List or Series of documents to embed
            
        Returns:
            Document embeddings as numpy array
        """
        if isinstance(texts, pd.Series):
            texts = texts.tolist()
        
        if len(texts) <= config.BATCH_SIZE:
            return self.embedding_model.encode(texts, show_progress_bar=True)
        
        embeddings = np.zeros((
            len(texts),
            self.embedding_model.get_sentence_embedding_dimension()
        ), dtype=np.float32)
        
        for i in range(0, len(texts), config.BATCH_SIZE):
            batch = texts[i:i + config.BATCH_SIZE]
            embeddings[i:i + len(batch)] = self.embedding_model.encode(
                batch,
                show_progress_bar=True
            )
        return embeddings

    def _initialize_stopwords(self, custom_stopwords: Optional[List[str]] = None) -> List[str]:
        """Initialize stopwords with error handling.
        
        Args:
            custom_stopwords: Additional stopwords to include
            
        Returns:
            List[str]: Combined list of stopwords
            
        Raises:
            RuntimeError: If stopwords initialization fails
        """
        try:
            nltk.download('stopwords', quiet=True)
            stop_words = list(stopwords.words('english'))
            if hasattr(config, 'STOPWORDS'):
                stop_words.extend(list(config.STOPWORDS))
            if custom_stopwords:
                stop_words.extend(custom_stopwords)
            return stop_words
        except Exception as e:
            logger.error(f"Error initializing stopwords: {str(e)}")
            raise RuntimeError(f"Failed to initialize stopwords: {str(e)}")

    @lru_cache(maxsize=10)
    def get_visualization(self, viz_type: str) -> Any:
        """Get visualization with improved error handling and validation.
        
        Args:
            viz_type: Type of visualization to generate ('topics', 'hierarchy', or 'heatmap')
            
        Returns:
            Any: Visualization object (typically plotly.graph_objs.Figure) or None if generation fails
            
        Note:
            - Validates model initialization and topic availability
            - Handles errors gracefully with logging
            - Returns None instead of raising exceptions for better UI handling
            - Supports standard BERTopic visualization types:
                - topics: Topic distribution visualization
                - hierarchy: Topic hierarchy visualization  
                - heatmap: Topic similarity heatmap
            
        Example:
            >>> viz = model.get_visualization('topics')
            >>> if viz:
            >>>     viz.show()
        """
        try:
            if not self.model:
                logger.error("Model not initialized")
                return None
            
            topic_info = self.model.get_topic_info()
            if topic_info.empty:
                logger.warning("No topics available for visualization")
                return None
            
            logger.info(f"Generating {viz_type} visualization")
            
            if viz_type == 'topics':
                return self.model.visualize_topics(width=1200, height=800)
            elif viz_type == 'hierarchy':
                return self.model.visualize_hierarchy(width=1200, height=800)
            elif viz_type == 'heatmap':
                return self.model.visualize_heatmap(width=1200, height=800)
            else:
                logger.error(f"Unknown visualization type: {viz_type}")
                return None
            
        except Exception as e:
            logger.error(f"Error generating {viz_type} visualization: {str(e)}")
            return None

    def get_wordcloud(self, topic_id: int) -> go.Figure:
        """Generate word cloud visualization for a topic."""
        if not isinstance(self.model, BERTopic):
            logger.error("Model not initialized for wordcloud")
            raise ValueError("Model not initialized")
        
        logger.info(f"Generating word cloud visualization for topic {topic_id}")
        
        try:
            # Get topic words and weights
            words = self.model.get_topic(topic_id)
            if not words:
                raise ValueError(f"No words found for topic {topic_id}")
            
            # Convert to word frequency dictionary
            word_freq = {word: weight for word, weight in words}
            
            # Create word cloud
            wordcloud = WordCloud(
                width=800,
                height=400,
                background_color='white',
                colormap='viridis'
            ).generate_from_frequencies(word_freq)
            
            # Create plotly figure
            fig = go.Figure()
            
            # Convert wordcloud to image
            img = wordcloud.to_array()
            
            # Add image to figure
            fig.add_trace(go.Image(z=img))
            
            # Update layout
            fig.update_layout(
                width=800,
                height=400,
                margin=dict(l=0, r=0, t=0, b=0),
                xaxis=dict(showticklabels=False, showgrid=False),
                yaxis=dict(showticklabels=False, showgrid=False)
            )
            
            return fig
            
        except Exception as e:
            logger.error(f"Error generating word cloud visualization: {str(e)}")
            raise

    def get_word_scores(self, topic_id: int) -> go.Figure:
        """Generate word score visualization for a topic."""
        if not isinstance(self.model, BERTopic):
            logger.error("Model not initialized for word scores")
            raise ValueError("Model not initialized")
        
        try:
            topic_info = self.model.get_topic_info()
            topics = topic_info[topic_info['Topic'] != -1]['Topic'].tolist()
            
            # Create bar chart with adjusted dimensions
            fig = self.model.visualize_barchart(
                topics=topics, 
                n_words=10,  # Reduced from 15
                width=400,   # Adjusted width
                height=800   # Matched to other visualizations
            )
            
            # Adjust layout for better visibility
            fig.update_layout(
                showlegend=True,
                margin=dict(l=50, r=20, t=30, b=20),
                yaxis=dict(
                    tickfont=dict(size=10),
                    showgrid=True,
                    gridwidth=1,
                    gridcolor='rgba(0,0,0,0.1)'
                ),
                xaxis=dict(
                    tickfont=dict(size=10),
                    showgrid=True,
                    gridwidth=1,
                    gridcolor='rgba(0,0,0,0.1)'
                ),
                plot_bgcolor='white'
            )
            return fig
        except Exception as e:
            logger.error(f"Error generating word score visualization: {str(e)}")
            raise

    @decorators.with_status("Topic Modeling", "Starting topic modeling...", "Topic modeling complete")
    async def fit_transform_dataframe(self, df: pd.DataFrame) -> pd.DataFrame:
        """Fit model and transform DataFrame with topic assignments.
        
        Args:
            df: Input DataFrame containing 'Comment' column
            
        Returns:
            DataFrame with added columns:
                - Topic: Integer topic ID
                - Topic_Name: String topic name from seed topics or auto-generated
                
        Raises:
            ValueError: If required columns missing or no valid documents
            RuntimeError: If topic modeling fails
            
        Note:
            - Validates and cleans input documents
            - Verifies seed topic assignment if seed topics provided
            - Maps topic IDs to names using topic_name_map
            - Handles outlier topic (-1) appropriately
            - Logs warnings if seed topics not fully assigned
        """
        try:
            # Validate input
            if 'Comment' not in df.columns:
                raise ValueError("DataFrame must contain 'Comment' column")
            
            # Get documents and validate
            documents = df['Comment'].astype(str).tolist()
            if not documents:
                raise ValueError("No valid documents found")
            
            # Clean and validate documents
            valid_docs = []
            for doc in documents:
                cleaned = ' '.join(word for word in doc.split() if len(word) >= 3)
                if len(cleaned.split()) >= 5:  # Require at least 5 words
                    valid_docs.append(cleaned)
            
            # Fit model and get topics
            topics, probs = self.model.fit_transform(valid_docs, self._generate_embeddings(valid_docs))
            logger.info(f"Generated {len(set(topics) - {-1})} topics")
            
            # Generate topic names
            topic_names = self._generate_topic_names(topics)
            
            # Add topics to DataFrame
            result_df = df.copy()
            result_df['Topic'] = topics
            result_df['Topic_Name'] = result_df['Topic'].apply(
                lambda t: topic_names.get(t, f"Topic {t}")
            )
            
            return result_df
            
        except Exception as e:
            error_msg = f"Topic modeling failed: {str(e)}"
            logger.error(error_msg, exc_info=True)
            raise RuntimeError(error_msg)

    @decorators.with_status("Topic Assignment", "Assigning topics...", "Topic assignment complete")
    async def transform(
        self,
        texts: Union[List[str], pd.Series]
    ) -> Tuple[List[int], np.ndarray]:
        """Transform texts to topic assignments.
        
        Args:
            texts: Documents to assign topics to
            
        Returns:
            Tuple of (topic assignments, topic probabilities)
            
        Raises:
            ValueError: If input is empty or model not initialized
        """
        if not texts:
            raise ValueError("Input texts cannot be empty")
            
        if isinstance(texts, pd.Series):
            texts = texts.tolist()
        texts = [str(t).strip() for t in texts if t is not None and str(t).strip()]
        
        if not isinstance(self.model, BERTopic):
            raise ValueError("Model not properly initialized")
            
        embeddings = self._generate_embeddings(texts)
        return self.model.transform(documents=texts, embeddings=embeddings)

    async def generate_topic_summary(self, output_dir: Path) -> Optional[Path]:
        """Generate comprehensive topic modeling summary report.
        
        Args:
            output_dir: Directory to save report
            
        Returns:
            Path to generated report file
        """
        if not isinstance(self.model, BERTopic):
            logger.error("Model not initialized for summary")
            return None
        
        try:
            logger.info("Generating topic summary report")
            
            # Get topic info
            topic_info = self.model.get_topic_info()
            
            # Generate report HTML
            report_content = ["<html><body>"]
            report_content.append("<h1>Topic Modeling Summary Report</h1>")
            
            # Human-labeled topics if available
            if hasattr(self, 'document_df') and 'Topic-Human' in self.document_df.columns:
                report_content.append("<h2>Human-Labeled Topics</h2>")
                report_content.append("<table border='1'>")
                report_content.append("<tr><th>Topic</th><th>Count</th></tr>")
                
                # Get value counts, excluding empty/null values
                human_topics = self.document_df['Topic-Human'].value_counts(dropna=True)
                for topic, count in human_topics.items():
                    if str(topic).strip():  # Only include non-empty topics
                        report_content.append(f"<tr><td>{topic}</td><td>{count}</td></tr>")
                
                report_content.append("</table>")
            
            # Model-generated topics
            report_content.append("<h2>Model-Generated Topics</h2>")
            report_content.append("<table border='1'>")
            report_content.append("<tr><th>Topic ID</th><th>Count</th><th>Top Words</th></tr>")
            
            for _, row in topic_info.iterrows():
                topic_id = row['Topic']
                if topic_id != -1:  # Skip outlier topic
                    words = self.model.get_topic(topic_id)
                    top_words = ", ".join(word for word, _ in words[:5])
                    report_content.append(
                        f"<tr><td>{topic_id}</td><td>{row['Count']}</td><td>{top_words}</td></tr>"
                    )
            
            report_content.append("</table>")
            report_content.append("</body></html>")
            
            # Save report
            report_path = output_dir / "topic_summary.html"
            report_path.write_text("\n".join(report_content))
            logger.info(f"Saved topic summary report to {report_path}")
            
            return report_path
            
        except Exception as e:
            logger.error(f"Error generating topic summary: {str(e)}")
            return None

    async def generate_topic_report(self, output_dir: Path) -> Optional[Path]:
        """Generate comprehensive topic modeling analysis report.
        
        Args:
            output_dir: Directory to save the report
            
        Returns:
            Path to generated report file or None if generation fails
        """
        if not isinstance(self.model, BERTopic):
            logger.error("Model not initialized for report")
            return None
        
        try:
            logger.info("Generating topic modeling report")
            
            # Get model info
            topic_info = self.model.get_topic_info()
            topic_names = self._generate_topic_names(topic_info['Topic'].tolist())
            
            # Generate report HTML with app-consistent styling
            report = ["""
            <html>
            <head>
                <style>
                    body { padding: 20px; font-family: Arial, sans-serif; }
                    .card { border: 1px solid #dee2e6; border-radius: 4px; margin-bottom: 20px; }
                    .card-header { background: #f8f9fa; padding: 10px; border-bottom: 1px solid #dee2e6; }
                    .card-body { padding: 15px; }
                    table { width: 100%; border-collapse: collapse; }
                    th, td { padding: 8px; text-align: left; border-bottom: 1px solid #dee2e6; }
                    tr:nth-child(even) { background-color: #f8f9fa; }
                </style>
            </head>
            <body>
            """]
            
            # Model overview
            report.append("""<div class="card">
                <div class="card-header"><h2>Topic Model Summary</h2></div>
                <div class="card-body">""")
            
            # Add summary statistics
            total_docs = topic_info['Count'].sum()
            outliers = topic_info[topic_info['Topic'] == -1]['Count'].sum()
            report.append(f"""
                <p>Total Documents: {total_docs}</p>
                <p>Topics Found: {len(topic_info) - 1}</p>
                <p>Outlier Documents: {outliers} ({(outliers/total_docs)*100:.1f}%)</p>
            """)
            report.append("</div></div>")
            
            # Topic details
            report.append("""<div class="card">
                <div class="card-header"><h2>Topic Details</h2></div>
                <div class="card-body"><table>
                <tr><th>ID</th><th>Name</th><th>Documents</th><th>Keywords</th></tr>""")
            
            # Add topic details
            for _, row in topic_info.iterrows():
                topic_id = row['Topic']
                if topic_id != -1:  # Skip outlier topic
                    words = self.model.get_topic(topic_id)
                    keywords = ", ".join(f"{word} ({weight:.2f})" 
                                      for word, weight in words[:5])
                    
                    report.append(f"""
                        <tr>
                            <td>{topic_id}</td>
                            <td>{topic_names.get(topic_id, '')}</td>
                            <td>{row['Count']}</td>
                            <td>{keywords}</td>
                        </tr>
                    """)
            
            report.append("</table></div></div></body></html>")
            
            # Save report
            report_path = output_dir / "topic_modeling_report.html"
            report_path.write_text("\n".join(report))
            logger.info(f"Saved topic modeling report to {report_path}")
            
            return report_path
            
        except Exception as e:
            logger.error(f"Error generating topic report: {str(e)}")
            return None

    def compare_topics(self, df: pd.DataFrame) -> Dict[str, Any]:
        """Compare model topics with human annotations.
        
        A high-level wrapper function that validates prerequisites and initiates
        detailed topic comparison analysis.
        
        Args:
            df: DataFrame containing both model-generated topics ('Topic' column)
                and human-assigned topics ('Topic-Human' column)
                
        Returns:
            Dictionary containing comparison metrics and analysis results
            
        Raises:
            ValueError: If required columns are missing or model is not fitted
        """
        if 'Topic-Human' not in df.columns or 'Topic' not in df.columns:
            raise ValueError("Missing required columns: 'Topic-Human' and 'Topic'")
        
        if not self.model or not self.document_topics:
            raise ValueError("Model must be fitted before comparison")
            
        return self.compare_topic_assignments(df)

    def compare_topic_assignments(
        self,
        df: pd.DataFrame,
        output_dir: Optional[Path] = None,
        min_docs: int = 5,
        status_manager: Optional[StatusProtocol] = None
    ) -> Dict[str, Any]:
        """Compare model-generated topics with human-assigned topics.
        
        Performs detailed comparison analysis between model-assigned and human-assigned
        topics, calculating various metrics and generating visualization outputs.
        
        Args:
            df: DataFrame containing both model-generated and human-assigned topics
            output_dir: Optional directory path for saving comparison outputs
            min_docs: Minimum number of documents required per topic for analysis
            status_manager: Optional status manager for progress tracking
            
        Returns:
            Dictionary containing:
                - chi_square: Chi-square test statistic
                - p_value: Statistical significance
                - dof: Degrees of freedom
                - kappa: Cohen's Kappa score
                - alignments: Topic alignment details
                - contingency: Contingency table
                
        Raises:
            Exception: If comparison fails, with detailed error message
        """
        try:
            if status_manager:
                status_manager.update_status("Comparison", 0, "Starting comparison")
            
            # Create and filter contingency table
            contingency = pd.crosstab(
                df['Topic'].fillna(-1),
                df['Topic-Human'].fillna('Unassigned')
            )
            filtered = contingency[contingency.sum(axis=1) >= min_docs]
            
            # Calculate metrics
            chi2, p_value, dof, _ = chi2_contingency(filtered)
            kappa = self._calculate_kappa(filtered)
            
            # Calculate alignments with explicit type handling
            alignments = {
                str(topic): {
                    'best_match': row.idxmax(),
                    'overlap_pct': round((row.max() / row.sum()) * 100, 2),
                    'total_docs': int(row.sum())
                }
                for topic, row in filtered.iterrows()
            }
            
            metrics = {
                'chi_square': float(chi2),
                'p_value': float(p_value),
                'dof': int(dof),
                'kappa': float(kappa),
                'alignments': alignments,
                'contingency': filtered.to_dict()
            }
            
            if output_dir:
                self._save_comparison_outputs(metrics, output_dir)
            
            if status_manager:
                status_manager.update_status("Comparison", 100, "Complete")
            
            return metrics
            
        except Exception as e:
            if status_manager:
                status_manager.set_error(f"Comparison failed: {str(e)}")
            raise

    def _calculate_kappa(self, contingency: pd.DataFrame) -> float:
        """Calculate Cohen's Kappa score for topic agreement.
        
        Computes the inter-rater reliability score between model-assigned
        and human-assigned topics using the contingency table.
        
        Args:
            contingency: Contingency table of topic assignments
            
        Returns:
            float: Kappa score between -1 and 1, where:
                1 = perfect agreement
                0 = agreement by chance
                -1 = perfect disagreement
                
        Note:
            Returns 0.0 if calculation fails, with error logged
        """
        try:
            from sklearn.metrics import cohen_kappa_score
            
            # Flatten contingency table to arrays
            model_topics = np.repeat(contingency.index.values, contingency.sum(axis=1).astype(int))
            human_topics = np.concatenate([
                np.repeat(col, row.astype(int)) 
                for col, row in contingency.items()
            ])
            
            return float(cohen_kappa_score(model_topics, human_topics))
            
        except Exception as e:
            logger.error(f"Kappa calculation error: {str(e)}")
            return 0.0

    def _save_comparison_outputs(self, metrics: Dict[str, Any], output_dir: Path) -> None:
        """Save topic comparison outputs to files.
        
        Generates and saves:
        - Contingency table (CSV)
        - Alignment heatmap (HTML)
        - Detailed report (TXT)
        
        Args:
            metrics: Dictionary containing comparison metrics and results
            output_dir: Directory path for saving outputs
            
        Note:
            Creates 'topic_comparison' subdirectory if it doesn't exist
        """
        comparison_dir = Path(output_dir) / 'topic_comparison'
        comparison_dir.mkdir(parents=True, exist_ok=True)
        
        # Save contingency table
        pd.DataFrame(metrics['contingency']).to_csv(comparison_dir / 'topic_comparison.csv')
        
        # Save heatmap
        fig = self._generate_comparison_heatmap(pd.DataFrame(metrics['contingency']))
        fig.write_html(str(comparison_dir / 'alignment_heatmap.html'))
        
        # Write detailed report
        with open(comparison_dir / 'comparison_report.txt', 'w') as f:
            f.write(f"Topic Comparison Results\n{'='*25}\n\n")
            f.write(f"Overall Metrics:\n")
            f.write(f"- Kappa Score: {metrics['kappa']:.3f}\n")
            f.write(f"- Chi-square: {metrics['chi_square']:.2f}\n")
            f.write(f"- p-value: {metrics['p_value']:.4f}\n\n")
            f.write("Topic Alignments:\n")
            for topic, align in metrics['alignments'].items():
                f.write(f"Topic {topic}:\n")
                f.write(f"  Best Match: {align['best_match']}\n")
                f.write(f"  Overlap: {align['overlap_pct']:.1f}%\n")
                f.write(f"  Documents: {align['total_docs']}\n\n")

    def _validate_config(self, config_dict: Dict[str, Any]) -> Dict[str, Any]:
        """Validate and normalize configuration dictionary."""
        required_keys = {
            'UMAP', 'EMBEDDING', 'TOPIC', 'NGRAM_RANGE', 
            'TOP_N_WORDS', 'CALCULATE_PROBABILITIES', 'LOW_MEMORY'
        }
        if missing := required_keys - set(config_dict.keys()):
            raise ValueError(f"Missing required config keys: {missing}")
        
        # Validate nested structures
        if 'UMAP' in config_dict:
            required_umap = {'n_neighbors', 'min_dist', 'metric'}
            if missing := required_umap - set(config_dict['UMAP'].keys()):
                raise ValueError(f"Missing UMAP config keys: {missing}")
            
        if 'EMBEDDING' in config_dict:
            required_embed = {'model', 'batch_size', 'random_seed'}
            if missing := required_embed - set(config_dict['EMBEDDING'].keys()):
                raise ValueError(f"Missing EMBEDDING config keys: {missing}")
            
        return config_dict

    def _initialize_vectorizer(self) -> CountVectorizer:
        """Initialize CountVectorizer with optimized settings.
        
        Returns:
            CountVectorizer: Configured vectorizer for text feature extraction
            
        Note:
            - Uses NLTK stopwords plus custom stopwords from config
            - Sets ngram_range from config for multi-word features
            - Uses dynamic min_df and max_df thresholds
            - Handles vocabulary size limits based on dataset
            
        Raises:
            RuntimeError: If initialization fails
        """
        try:
            # Get stopwords
            stop_words = list(stopwords.words('english'))
            if hasattr(config, 'STOPWORDS'):
                stop_words.extend(list(config.STOPWORDS))
            
            # Use more lenient document frequency thresholds
            return CountVectorizer(
                ngram_range=self.config['NGRAM_RANGE'],
                stop_words=stop_words,
                min_df=1,      # Allow words appearing in at least 1 document
                max_df=1.0,    # Allow words appearing in all documents
                max_features=self.config.get('MAX_FEATURES', 20000)
            )
        except Exception as e:
            logger.error(f"Error initializing vectorizer: {str(e)}")
            raise RuntimeError(f"Failed to initialize vectorizer: {str(e)}")

    def _initialize_umap(self) -> UMAP:
        """Initialize UMAP model.
        
        Returns:
            UMAP: Configured UMAP instance
        """
        return UMAP(
            n_neighbors=self.config['UMAP']['n_neighbors'],
            min_dist=self.config['UMAP']['min_dist'],
            metric=self.config['UMAP']['metric'],
            random_state=42
        )

    def _get_file_list(self, output_dir: Path) -> List[Path]:
        """Get list of output files.
        
        Args:
            output_dir: Directory containing output files
            
        Returns:
            List[Path]: List of output file paths
            
        Note:
            Collects all generated output files for the session.
        """
        if not isinstance(output_dir, Path):
            output_dir = Path(output_dir)
        
        files = []
        for pattern in ['*.csv', '*.html', '*.txt']:
            files.extend(output_dir.glob(pattern))
        
        # Also check subdirectories
        for subdir in ['reports', 'visualizations']:
            subdir_path = output_dir / subdir
            if subdir_path.exists():
                for pattern in ['*.csv', '*.html', '*.txt']:
                    files.extend(subdir_path.glob(pattern))
                
        return files

    def _check_memory_usage(self) -> None:
        """Monitor memory usage during processing."""
        try:
            import psutil
            process = psutil.Process()
            memory_info = process.memory_info()
            memory_percent = process.memory_percent()
            
            logger.info(f"Memory usage: {memory_info.rss / 1024 / 1024:.2f} MB ({memory_percent:.1f}%)")
            
            if memory_percent > 80:
                logger.warning("High memory usage detected")
            
        except ImportError:
            logger.debug("psutil not available for memory monitoring")

    async def _process_in_batches(self, documents: List[str], batch_size: int = 1000) -> Tuple[np.ndarray, np.ndarray]:
        """Process documents in batches to manage memory."""
        try:
            total_batches = (len(documents) + batch_size - 1) // batch_size
            all_topics = []
            all_probs = []
            
            for i in range(0, len(documents), batch_size):
                batch = documents[i:i + batch_size]
                
                if self.status_manager:
                    progress = (i / len(documents)) * 100
                    self.status_manager.update_status(
                        "Modeling",
                        progress,
                        f"Processing batch {i//batch_size + 1}/{total_batches}"
                    )
                
                # Generate embeddings for batch
                embeddings = self._generate_embeddings(batch)
                
                # Process batch
                topics, probs = self.model.fit_transform(batch, embeddings)
                
                all_topics.extend(topics)
                all_probs.append(probs)
                
                self._check_memory_usage()
                
            return np.array(all_topics), np.vstack(all_probs)
            
        except Exception as e:
            logger.error(f"Batch processing failed: {str(e)}", exc_info=True)
            raise

    def _check_bertopic_version(self) -> None:
        """Check BERTopic version compatibility."""
        try:
            import bertopic
            version = bertopic.__version__
            logger.info(f"BERTopic version: {version}")
            
            major, minor, _ = version.split('.')
            version_num = int(major) * 100 + int(minor)
            
            if version_num < 200:  # version < 2.0
                logger.warning("Using legacy BERTopic version - some features may be limited")
                self.legacy_mode = True
            else:
                self.legacy_mode = False
            
        except Exception as e:
            logger.error(f"Version check failed: {str(e)}")
            self.legacy_mode = True

    def get_topic_visualization(self) -> go.Figure:
        """Generate topic distribution visualization."""
        if not isinstance(self.model, BERTopic):
            raise ValueError("Model not initialized")
        
        try:
            # Get topic info excluding outlier topic (-1)
            topic_info = self.model.get_topic_info()
            logger.info(f"Total topics found: {len(topic_info)}")
            logger.info(f"Topic distribution:\n{topic_info['Topic'].value_counts()}")
            
            valid_topics = topic_info[topic_info['Topic'] != -1]
            logger.info(f"Valid topics after filtering: {len(valid_topics)}")
            
            if valid_topics.empty:
                return self._create_empty_plot("No topics to visualize")
            
            # Create bar plot of topic sizes with topic words
            sizes = valid_topics['Count'].tolist()
            topics = valid_topics['Topic'].tolist()
            
            # Get top words for each topic
            labels = []
            for topic_id in topics:
                words = self.model.get_topic(topic_id)
                top_words = ', '.join(word for word, _ in words[:3])
                labels.append(f"Topic {topic_id}<br>({top_words})")
            
            fig = go.Figure(data=[
                go.Bar(
                    x=labels,
                    y=sizes,
                    text=sizes,
                    textposition='auto',
                    hovertemplate="<b>%{x}</b><br>" +
                                "Documents: %{y}<br>" +
                                "<extra></extra>"
                )
            ])
            
            fig.update_layout(
                title="Topic Distribution",
                xaxis_title="Topics",
                yaxis_title="Number of Documents",
                showlegend=False,
                xaxis={'tickangle': 45},
                margin=dict(b=100)  # Increase bottom margin for labels
            )
            
            return fig
            
        except Exception as e:
            logger.error(f"Error generating topic visualization: {str(e)}")
            return self._create_empty_plot(f"Error: {str(e)}")

    def _create_empty_plot(self, message: str) -> go.Figure:
        """Create empty plot with message."""
        fig = go.Figure()
        fig.add_annotation(
            text=message,
            xref="paper", yref="paper",
            x=0.5, y=0.5,
            showarrow=False
        )
        return fig

    def get_topic_hierarchy(self) -> go.Figure:
        """Generate topic hierarchy visualization."""
        if not isinstance(self.model, BERTopic):
            raise ValueError("Model not initialized")
            
        try:
            # Check if we have valid topics
            topic_info = self.model.get_topic_info()
            valid_topics = topic_info[topic_info['Topic'] != -1]
            
            if valid_topics.empty:
                logger.warning("No valid topics found for hierarchy")
                fig = go.Figure()
                fig.add_annotation(
                    text="No topics to visualize",
                    xref="paper", yref="paper",
                    x=0.5, y=0.5,
                    showarrow=False
                )
                return fig
            
            return self.model.visualize_hierarchy(
                width=800,
                height=600
            )
        except Exception as e:
            logger.error(f"Error generating hierarchy: {str(e)}")
            raise

    def get_topic_wordcloud(self) -> plt.Figure:
        """Generate word cloud visualization for topics.
        
        Returns:
            plt.Figure: Matplotlib figure containing the word cloud visualization
                - Shows frequency-weighted words from all valid topics
                - Uses viridis colormap for consistent visualization
                - Maintains aspect ratio for readability
                - Returns empty plot with message if no valid topics/words
                
        Raises:
            ValueError: If model is not initialized
            
        Note:
            - Excludes outlier topic (-1)
            - Combines words from all topics with weight-based sizing
            - Handles word frequency normalization
            - Provides graceful fallback for visualization errors
            - Ensures proper figure cleanup
        """
        if not isinstance(self.model, BERTopic):
            raise ValueError("Model not initialized")
        
        try:
            # Get topic info excluding outlier topic (-1)
            topic_info = self.model.get_topic_info()
            valid_topics = topic_info[topic_info['Topic'] != -1]
            
            if valid_topics.empty:
                logger.warning("No valid topics found for word cloud")
                return self._create_empty_plot("No topics to visualize")
            
            # Create word frequency dictionary for all topics
            word_freqs = {}
            for topic_id in valid_topics['Topic']:
                try:
                    words = self.model.get_topic(topic_id)
                    if not words:
                        continue
                    
                    # Process each word and weight
                    for word, weight in words:
                        if not isinstance(word, str) or not word.strip():
                            continue
                        # Ensure positive weights and convert to float
                        weight_val = abs(float(weight))
                        word_freqs[word.strip()] = word_freqs.get(word.strip(), 0) + weight_val
                    
                except Exception as e:
                    logger.warning(f"Error processing topic {topic_id}: {str(e)}")
                    continue
            
            if not word_freqs:
                logger.warning("No valid words found for visualization")
                return self._create_empty_plot("No words to visualize")
            
            # Normalize frequencies if needed
            max_freq = max(word_freqs.values())
            if max_freq > 1:
                word_freqs = {word: freq/max_freq for word, freq in word_freqs.items()}
            
            # Generate word cloud
            wordcloud = WordCloud(
                width=1200,
                height=800,
                background_color='white',
                colormap='viridis',
                prefer_horizontal=0.7,
                min_font_size=8,
                max_font_size=80
            ).generate_from_frequencies(word_freqs)
            
            # Create figure and plot
            fig, ax = plt.subplots(figsize=(12, 8), dpi=100)
            ax.imshow(wordcloud, interpolation='bilinear')
            ax.axis('off')
            plt.tight_layout(pad=0)
            
            return fig
            
        except Exception as e:
            logger.error(f"Error generating wordcloud: {str(e)}")
            return self._create_empty_plot(f"Error: {str(e)}")

    def update_seed_topics(self, seed_topics: List[str]) -> None:
        """Update seed topics and regenerate topic names if model exists.
        
        Args:
            seed_topics: List of seed topic strings
            
        Note:
            - Updates stored seed topics
            - Regenerates topic names if model exists
            - Maintains existing topic assignments
        """
        try:
            validated_topics = self._validate_seed_topics(seed_topics)
            if validated_topics:
                # Store new seed topics
                self.seed_topics = validated_topics
                
                # Regenerate topic names if model exists
                if self.model:
                    topic_names = self._generate_topic_names(topic_info['Topic'].tolist())
                    # Update model's topic labels if possible
                    if hasattr(self.model, 'set_topic_labels'):
                        self.model.set_topic_labels(topic_names)
                    logger.info("Updated topic names with new seed topics")
        except Exception as e:
            logger.error(f"Failed to update seed topics: {str(e)}")

async def save_topic_modeling_outputs(
    model: TopicModeler,
    df: pd.DataFrame,
    output_dir: Path,
    session_manager: Optional[SessionManager] = None
) -> Dict[str, Any]:
    """Save topic modeling outputs and generate visualizations.
    
    Args:
        model: Trained TopicModeler instance
        df: DataFrame with topic assignments
        output_dir: Output directory path
        session_manager: Optional session manager
        
    Returns:
        Dict containing model and distribution DataFrame
    """
    try:
        # Create output directories
        output_dir = Path(output_dir)
        viz_dir = output_dir / "visualizations"
        viz_dir.mkdir(exist_ok=True, parents=True)
        
        # Save topic assignments
        df_path = output_dir / config.TOPIC_OUTPUT_CONFIG['DEFAULT_FILENAME']
        df.to_csv(df_path, index=False)
        logger.info(f"Saved topic assignments to {df_path}")
        
        if session_manager:
            session_manager.add_file(str(df_path))
        
        # Generate and save visualizations
        try:
            # Save visualizations
            for viz_type, (viz_func, suffix) in {
                'distribution': (model.get_topic_visualization, 'html'),
                'hierarchy': (model.get_topic_hierarchy, 'html'),
                'wordcloud': (model.get_topic_wordcloud, 'png')
            }.items():
                try:
                    viz = viz_func()
                    path = viz_dir / f"topic_{viz_type}.{suffix}"
                    
                    if suffix == 'html':
                        viz.write_html(str(path))
                    else:
                        viz.savefig(path, bbox_inches='tight', dpi=300)
                        plt.close()
                    
                    if session_manager and path.exists():
                        session_manager.add_file(str(path))
                        logger.info(f"Added visualization: {path.name}")
                    
                except Exception as e:
                    logger.error(f"Error saving {viz_type}: {str(e)}")
            
            return {
                'model': model,
                'distribution': df
            }
            
        except Exception as e:
            logger.error(f"Error generating visualizations: {str(e)}")
            
    except Exception as e:
        error_msg = f"Failed to save topic modeling outputs: {str(e)}"
        logger.error(error_msg, exc_info=True)
        raise RuntimeError(error_msg)
     